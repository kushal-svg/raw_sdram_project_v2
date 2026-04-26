module sdram_controller #(
    parameter int CLK_FREQ_HZ      = 50_000_000,
    parameter int INIT_WAIT_CYCLES = 10_000,   // 200 us @ 50 MHz
    parameter int REFRESH_CYCLES   = 390,      // ~7.8 us @ 50 MHz
    parameter int BURST_WORDS      = 512
) (
    // FPGA side
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rw,           // 1: read, 0: write
    input  logic        rw_en,        // request pulse
    input  logic [14:0] f_addr,       // [14:2]=row, [1:0]=bank
    input  logic [15:0] f2s_data,
    output logic [15:0] s2f_data,
    output logic        s2f_data_valid,
    output logic        f2s_data_valid,
    output logic        ready,

    // SDRAM side
    output logic        s_clk,
    output logic        s_cke,
    output logic        s_cs_n,
    output logic        s_ras_n,
    output logic        s_cas_n,
    output logic        s_we_n,
    output logic [12:0] s_addr,
    output logic [1:0]  s_ba,
    output logic        LDQM,
    output logic        UDQM,
    inout  wire  [15:0] s_dq
);

    localparam int T_RP  = 2;  // conservative @ 50 MHz
    localparam int T_RC  = 4;
    localparam int T_MRD = 2;
    localparam int T_RCD = 2;
    localparam int T_WR  = 2;
    localparam int T_CL  = 2;

    localparam logic [3:0] CMD_SETMODE   = 4'b0000;
    localparam logic [3:0] CMD_REFRESH   = 4'b0001;
    localparam logic [3:0] CMD_PRECHARGE = 4'b0010;
    localparam logic [3:0] CMD_ACTIVATE  = 4'b0011;
    localparam logic [3:0] CMD_WRITE     = 4'b0100;
    localparam logic [3:0] CMD_READ      = 4'b0101;
    localparam logic [3:0] CMD_NOP       = 4'b0111;
    localparam logic [3:0] CMD_DESELECT  = 4'b1111;

    typedef enum logic [3:0] {
        ST_START          = 4'd0,
        ST_PRECHARGE_INIT = 4'd1,
        ST_REFRESH_1      = 4'd2,
        ST_REFRESH_2      = 4'd3,
        ST_LOAD_MODE      = 4'd4,
        ST_IDLE           = 4'd5,
        ST_READ_CMD       = 4'd6,
        ST_READ_DATA      = 4'd7,
        ST_WRITE_CMD      = 4'd8,
        ST_WRITE_BURST    = 4'd9,
        ST_REFRESH        = 4'd10,
        ST_DELAY          = 4'd11
    } state_t;

    state_t state_q, state_d;
    state_t nxt_q, nxt_d;

    logic [3:0]  cmd_q, cmd_d;
    logic [15:0] delay_ctr_q, delay_ctr_d;
    logic [15:0] refresh_ctr_q, refresh_ctr_d;
    logic        refresh_flag_q, refresh_flag_d;
    logic [9:0]  burst_index_q, burst_index_d;

    logic        rw_q, rw_d;
    logic        req_pending_q, req_pending_d;
    logic [14:0] f_addr_q, f_addr_d;
    logic [15:0] f2s_data_q, f2s_data_d;
    logic [15:0] s2f_data_q, s2f_data_d;
    logic        s2f_data_valid_q, s2f_data_valid_d;

    logic [12:0] s_addr_q, s_addr_d;
    logic [1:0]  s_ba_q, s_ba_d;
    logic        dq_drive_q, dq_drive_d;

    // Direct clock for conservative 50 MHz bring-up.
    assign s_clk = clk;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q          <= ST_START;
            nxt_q            <= ST_START;
            cmd_q            <= CMD_DESELECT;
            delay_ctr_q      <= '0;
            refresh_ctr_q    <= '0;
            refresh_flag_q   <= 1'b0;
            burst_index_q    <= '0;
            rw_q             <= 1'b0;
            req_pending_q    <= 1'b0;
            f_addr_q         <= '0;
            f2s_data_q       <= '0;
            s2f_data_q       <= '0;
            s2f_data_valid_q <= 1'b0;
            s_addr_q         <= '0;
            s_ba_q           <= '0;
            dq_drive_q       <= 1'b0;
        end else begin
            state_q          <= state_d;
            nxt_q            <= nxt_d;
            cmd_q            <= cmd_d;
            delay_ctr_q      <= delay_ctr_d;
            refresh_ctr_q    <= refresh_ctr_d;
            refresh_flag_q   <= refresh_flag_d;
            burst_index_q    <= burst_index_d;
            rw_q             <= rw_d;
            req_pending_q    <= req_pending_d;
            f_addr_q         <= f_addr_d;
            f2s_data_q       <= f2s_data_d;
            s2f_data_q       <= s2f_data_d;
            s2f_data_valid_q <= s2f_data_valid_d;
            s_addr_q         <= s_addr_d;
            s_ba_q           <= s_ba_d;
            dq_drive_q       <= dq_drive_d;
        end
    end

    always_comb begin
        state_d          = state_q;
        nxt_d            = nxt_q;
        cmd_d            = CMD_NOP;
        delay_ctr_d      = delay_ctr_q;
        refresh_ctr_d    = refresh_ctr_q;
        refresh_flag_d   = refresh_flag_q;
        burst_index_d    = burst_index_q;
        rw_d             = rw_q;
        req_pending_d    = req_pending_q;
        f_addr_d         = f_addr_q;
        f2s_data_d       = f2s_data;
        s2f_data_d       = s2f_data_q;
        s2f_data_valid_d = 1'b0;
        s_addr_d         = s_addr_q;
        s_ba_d           = s_ba_q;
        dq_drive_d       = 1'b0;
        ready            = 1'b0;
        f2s_data_valid   = 1'b0;

        // refresh timer runs during normal operation
        refresh_ctr_d = refresh_ctr_q + 16'd1;
        if (refresh_ctr_q >= REFRESH_CYCLES-1) begin
            refresh_ctr_d  = '0;
            refresh_flag_d = 1'b1;
        end

        case (state_q)
            ST_DELAY: begin
                if (delay_ctr_q != 0)
                    delay_ctr_d = delay_ctr_q - 16'd1;
                else
                    state_d = nxt_q;

                if ((nxt_q == ST_WRITE_CMD) || (nxt_q == ST_WRITE_BURST))
                    dq_drive_d = 1'b1;
            end

            ST_START: begin
                state_d     = ST_DELAY;
                nxt_d       = ST_PRECHARGE_INIT;
                delay_ctr_d = INIT_WAIT_CYCLES;
                cmd_d       = CMD_DESELECT;
            end

            ST_PRECHARGE_INIT: begin
                state_d      = ST_DELAY;
                nxt_d        = ST_REFRESH_1;
                delay_ctr_d  = T_RP;
                cmd_d        = CMD_PRECHARGE;
                s_addr_d     = '0;
                s_addr_d[10] = 1'b1; // precharge all banks
            end

            ST_REFRESH_1: begin
                state_d     = ST_DELAY;
                nxt_d       = ST_REFRESH_2;
                delay_ctr_d = T_RC;
                cmd_d       = CMD_REFRESH;
            end

            ST_REFRESH_2: begin
                state_d     = ST_DELAY;
                nxt_d       = ST_LOAD_MODE;
                delay_ctr_d = T_RC;
                cmd_d       = CMD_REFRESH;
            end

            ST_LOAD_MODE: begin
                state_d     = ST_DELAY;
                nxt_d       = ST_IDLE;
                delay_ctr_d = T_MRD;
                cmd_d       = CMD_SETMODE;
                // Full-page burst, sequential, CAS=2, standard op, programmed burst write
                s_addr_d    = 13'b000_0_00_010_0_111;
                s_ba_d      = 2'b00;
            end

            ST_IDLE: begin
                ready = 1'b1;

                if (refresh_flag_q) begin
                    state_d        = ST_DELAY;
                    nxt_d          = ST_REFRESH;
                    delay_ctr_d    = T_RP;
                    cmd_d          = CMD_PRECHARGE;
                    s_addr_d       = '0;
                    s_addr_d[10]   = 1'b1;
                    refresh_flag_d = 1'b0;
                end else if (req_pending_q) begin
                    state_d       = ST_DELAY;
                    nxt_d         = rw_q ? ST_READ_CMD : ST_WRITE_CMD;
                    delay_ctr_d   = T_RCD;
                    cmd_d         = CMD_ACTIVATE;
                    burst_index_d = '0;
                    s_addr_d      = f_addr_q[14:2];
                    s_ba_d        = f_addr_q[1:0];
                    req_pending_d = 1'b0;
                end else if (rw_en) begin
                    f_addr_d      = f_addr;
                    rw_d          = rw;
                    req_pending_d = 1'b1;
                    // If refresh is not pending, next cycle will ACTIVATE.
                end
            end

            ST_REFRESH: begin
                state_d     = ST_DELAY;
                nxt_d       = ST_IDLE;
                delay_ctr_d = T_RC;
                cmd_d       = CMD_REFRESH;
            end

            ST_READ_CMD: begin
                state_d      = ST_DELAY;
                nxt_d        = ST_READ_DATA;
                delay_ctr_d  = T_CL;
                cmd_d        = CMD_READ;
                s_addr_d     = '0;       // column 0, full-page burst
                s_addr_d[10] = 1'b0;     // disable auto-precharge
                s_ba_d       = f_addr_q[1:0];
            end

            ST_READ_DATA: begin
                s2f_data_d       = s_dq;
                s2f_data_valid_d = 1'b1;
                burst_index_d    = burst_index_q + 10'd1;

                if (burst_index_q == BURST_WORDS-1) begin
                    s2f_data_valid_d = 1'b0;
                    state_d          = ST_DELAY;
                    nxt_d            = ST_IDLE;
                    delay_ctr_d      = T_RP;
                    cmd_d            = CMD_PRECHARGE;
                    s_addr_d         = '0;
                    s_addr_d[10]     = 1'b1;
                end
            end

            ST_WRITE_CMD: begin
                f2s_data_valid = 1'b1;
                dq_drive_d     = 1'b1;
                cmd_d          = CMD_WRITE;
                s_addr_d       = '0;      // column 0, full-page burst
                s_addr_d[10]   = 1'b0;    // disable auto-precharge
                s_ba_d         = f_addr_q[1:0];
                burst_index_d  = 10'd1;
                state_d        = ST_WRITE_BURST;
            end

            ST_WRITE_BURST: begin
                f2s_data_valid = 1'b1;
                dq_drive_d     = 1'b1;
                burst_index_d  = burst_index_q + 10'd1;

                if (burst_index_q == BURST_WORDS-1) begin
                    dq_drive_d    = 1'b0;
                    state_d       = ST_DELAY;
                    nxt_d         = ST_IDLE;
                    delay_ctr_d   = T_RP + T_WR;
                    cmd_d         = CMD_PRECHARGE;
                    s_addr_d      = '0;
                    s_addr_d[10]  = 1'b1;
                    f2s_data_valid = 1'b0;
                end
            end

            default: begin
                state_d = ST_START;
            end
        endcase
    end

    assign s_cs_n   = cmd_q[3];
    assign s_ras_n  = cmd_q[2];
    assign s_cas_n  = cmd_q[1];
    assign s_we_n   = cmd_q[0];
    assign s_cke    = 1'b1;
    assign LDQM     = 1'b0;
    assign UDQM     = 1'b0;
    assign s_addr   = s_addr_q;
    assign s_ba     = s_ba_q;
    assign s_dq     = dq_drive_q ? f2s_data_q : 16'hzzzz;
    assign s2f_data = s2f_data_q;
    assign s2f_data_valid = s2f_data_valid_q;

endmodule
