module comprehensive_tb (
    input  logic        MAX10_CLK1_50,
    input  logic [1:0]  KEY,
    input  logic [9:0]  SW,
    output logic [9:0]  LEDR,
    output logic [7:0]  HEX0,
    output logic [7:0]  HEX1,
    output logic [7:0]  HEX2,
    output logic [7:0]  HEX3,
    output logic [7:0]  HEX4,
    output logic [7:0]  HEX5,

    output logic [12:0] DRAM_ADDR,
    output logic [1:0]  DRAM_BA,
    output logic        DRAM_CAS_N,
    output logic        DRAM_CKE,
    output logic        DRAM_CLK,
    output logic        DRAM_CS_N,
    inout  wire  [15:0] DRAM_DQ,
    output logic        DRAM_LDQM,
    output logic        DRAM_UDQM,
    output logic        DRAM_RAS_N,
    output logic        DRAM_WE_N
);
    localparam int BURST_WORDS = 512;
    localparam logic [14:0] LAST_PAGE = 15'h7FFF; // all 32K page selections

    logic clk;
    logic rst_n;
    assign clk   = MAX10_CLK1_50;
    assign rst_n = SW[9];      // SW9 high = run, low = reset

    logic key0_tick, key1_tick;
    logic key0_level, key1_level;

    logic        rw;
    logic        rw_en;
    logic [14:0] f_addr;
    logic [15:0] f2s_data;
    logic [15:0] s2f_data;
    logic        s2f_data_valid;
    logic        f2s_data_valid;
    logic        ready;

    logic [36:0] error_q, error_d;
    logic [14:0] page_q, page_d;
    logic [9:0]  burst_idx_q, burst_idx_d;
    logic [36:0] words_q, words_d;

    typedef enum logic [2:0] {
        T_IDLE,
        T_WRITE_REQ,
        T_WRITE_RUN,
        T_READ_REQ,
        T_READ_RUN,
        T_DONE
    } tst_state_t;

    tst_state_t state_q, state_d;

    logic [5:0] in0, in1, in2, in3, in4, in5;
    logic [3:0] d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10;
    logic b2b_ready, b2b_done;

    function automatic logic [15:0] pattern(input logic [14:0] page, input logic [9:0] idx);
        pattern = {page[5:0], idx};
    endfunction

    debounce_explicit db0 (
        .clk(clk),
        .rst_n(rst_n),
        .sw(~KEY[0]),
        .db_level(key0_level),
        .db_tick(key0_tick)
    );

    debounce_explicit db1 (
        .clk(clk),
        .rst_n(rst_n),
        .sw(~KEY[1]),
        .db_level(key1_level),
        .db_tick(key1_tick)
    );

    sdram_controller #(
        .CLK_FREQ_HZ(50_000_000),
        .INIT_WAIT_CYCLES(10_000),
        .REFRESH_CYCLES(390),
        .BURST_WORDS(BURST_WORDS)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .rw(rw),
        .rw_en(rw_en),
        .f_addr(f_addr),
        .f2s_data(f2s_data),
        .s2f_data(s2f_data),
        .s2f_data_valid(s2f_data_valid),
        .f2s_data_valid(f2s_data_valid),
        .ready(ready),
        .s_clk(DRAM_CLK),
        .s_cke(DRAM_CKE),
        .s_cs_n(DRAM_CS_N),
        .s_ras_n(DRAM_RAS_N),
        .s_cas_n(DRAM_CAS_N),
        .s_we_n(DRAM_WE_N),
        .s_addr(DRAM_ADDR),
        .s_ba(DRAM_BA),
        .LDQM(DRAM_LDQM),
        .UDQM(DRAM_UDQM),
        .s_dq(DRAM_DQ)
    );

    bin2bcd u_b2b (
        .clk(clk),
        .rst_n(rst_n),
        .start(1'b1),
        .bin(error_q),
        .ready(b2b_ready),
        .done_tick(b2b_done),
        .dig0(d0), .dig1(d1), .dig2(d2), .dig3(d3), .dig4(d4), .dig5(d5),
        .dig6(d6), .dig7(d7), .dig8(d8), .dig9(d9), .dig10(d10)
    );

    assign in0 = {1'b0, d0};
    assign in1 = {1'b0, d1};
    assign in2 = {1'b0, d2};
    assign in3 = {1'b0, d3};
    assign in4 = {1'b0, d4};
    assign in5 = {1'b0, d5};

    LED_mux u_disp (
        .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q     <= T_IDLE;
            page_q      <= '0;
            burst_idx_q <= '0;
            error_q     <= '0;
            words_q     <= '0;
        end else begin
            state_q     <= state_d;
            page_q      <= page_d;
            burst_idx_q <= burst_idx_d;
            error_q     <= error_d;
            words_q     <= words_d;
        end
    end

    always_comb begin
        state_d     = state_q;
        page_d      = page_q;
        burst_idx_d = burst_idx_q;
        error_d     = error_q;
        words_d     = words_q;

        rw          = 1'b0;
        rw_en       = 1'b0;
        f_addr      = page_q;
        f2s_data    = pattern(page_q, burst_idx_q);

        LEDR        = '0;
        LEDR[9]     = ready;
        LEDR[8]     = key0_level;
        LEDR[7]     = key1_level;
        LEDR[6]     = (state_q == T_WRITE_RUN) || (state_q == T_WRITE_REQ);
        LEDR[5]     = (state_q == T_READ_RUN)  || (state_q == T_READ_REQ);
        LEDR[4]     = (error_q != 0);
        LEDR[3:0]   = page_q[3:0];

        case (state_q)
            T_IDLE: begin
                page_d      = '0;
                burst_idx_d = '0;
                words_d     = '0;
                if (key0_tick) begin
                    error_d = '0;
                    state_d = T_WRITE_REQ;
                end else if (key1_tick) begin
                    error_d = '0;
                    state_d = T_READ_REQ;
                end
            end

            T_WRITE_REQ: begin
                if (ready) begin
                    rw    = 1'b0;
                    rw_en = 1'b1;
                    f_addr = page_q;
                    burst_idx_d = '0;
                    state_d = T_WRITE_RUN;
                end
            end

            T_WRITE_RUN: begin
                f_addr   = page_q;
                f2s_data = pattern(page_q, burst_idx_q);
                if (SW[0] && (page_q == 15'd100 || page_q == 15'd13000))
                    f2s_data = 16'h9999; // injected error pages

                if (f2s_data_valid) begin
                    burst_idx_d = burst_idx_q + 10'd1;
                    words_d     = words_q + 37'd1;
                end else if (ready && (burst_idx_q != 0)) begin
                    burst_idx_d = '0;
                    if (page_q == LAST_PAGE) begin
                        state_d = T_DONE;
                    end else begin
                        page_d  = page_q + 15'd1;
                        state_d = T_WRITE_REQ;
                    end
                end
            end

            T_READ_REQ: begin
                if (ready) begin
                    rw    = 1'b1;
                    rw_en = 1'b1;
                    f_addr = page_q;
                    burst_idx_d = '0;
                    state_d = T_READ_RUN;
                end
            end

            T_READ_RUN: begin
                if (s2f_data_valid) begin
                    if (s2f_data != pattern(page_q, burst_idx_q))
                        error_d = error_q + 37'd1;
                    burst_idx_d = burst_idx_q + 10'd1;
                    words_d     = words_q + 37'd1;
                end else if (ready && (burst_idx_q != 0)) begin
                    burst_idx_d = '0;
                    if (page_q == LAST_PAGE) begin
                        state_d = T_DONE;
                    end else begin
                        page_d  = page_q + 15'd1;
                        state_d = T_READ_REQ;
                    end
                end
            end

            T_DONE: begin
                LEDR[0] = (error_q == 0);
                LEDR[1] = (error_q != 0);
                if (key0_tick)
                    state_d = T_WRITE_REQ;
                else if (key1_tick)
                    state_d = T_READ_REQ;
            end

            default: state_d = T_IDLE;
        endcase
    end
endmodule
