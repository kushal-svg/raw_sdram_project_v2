module bin2bcd #(
    parameter int N = 37
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [N-1:0] bin,
    output logic        ready,
    output logic        done_tick,
    output logic [3:0]  dig0,
    output logic [3:0]  dig1,
    output logic [3:0]  dig2,
    output logic [3:0]  dig3,
    output logic [3:0]  dig4,
    output logic [3:0]  dig5,
    output logic [3:0]  dig6,
    output logic [3:0]  dig7,
    output logic [3:0]  dig8,
    output logic [3:0]  dig9,
    output logic [3:0]  dig10
);
    typedef enum logic [1:0] {S_IDLE, S_OP, S_DONE} state_t;
    state_t state_q, state_d;

    logic [N-1:0] bin_q, bin_d;
    logic [3:0] bcd_q [0:10];
    logic [3:0] bcd_d [0:10];
    logic [$clog2(N+1)-1:0] n_q, n_d;

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
            bin_q   <= '0;
            n_q     <= '0;
            for (i = 0; i <= 10; i=i+1)
                bcd_q[i] <= '0;
        end else begin
            state_q <= state_d;
            bin_q   <= bin_d;
            n_q     <= n_d;
            for (i = 0; i <= 10; i=i+1)
                bcd_q[i] <= bcd_d[i];
        end
    end

    always_comb begin
        state_d   = state_q;
        bin_d     = bin_q;
        n_d       = n_q;
        done_tick = 1'b0;
        ready     = 1'b0;
        for (i = 0; i <= 10; i=i+1)
            bcd_d[i] = bcd_q[i];

        case (state_q)
            S_IDLE: begin
                ready = 1'b1;
                if (start) begin
                    bin_d = bin;
                    n_d   = N;
                    for (i = 0; i <= 10; i=i+1)
                        bcd_d[i] = '0;
                    state_d = S_OP;
                end
            end

            S_OP: begin
                for (i = 0; i <= 10; i=i+1)
                    if (bcd_q[i] > 4)
                        bcd_d[i] = bcd_q[i] + 4'd3;

                {bcd_d[10], bcd_d[9], bcd_d[8], bcd_d[7], bcd_d[6], bcd_d[5],
                 bcd_d[4], bcd_d[3], bcd_d[2], bcd_d[1], bcd_d[0], bin_d}
                    = {bcd_d[10], bcd_d[9], bcd_d[8], bcd_d[7], bcd_d[6], bcd_d[5],
                       bcd_d[4], bcd_d[3], bcd_d[2], bcd_d[1], bcd_d[0], bin_q} << 1;

                n_d = n_q - 1'b1;
                if (n_q == 1)
                    state_d = S_DONE;
            end

            S_DONE: begin
                done_tick = 1'b1;
                ready     = 1'b1;
                state_d   = S_IDLE;
            end
        endcase
    end

    assign dig0  = bcd_q[0];
    assign dig1  = bcd_q[1];
    assign dig2  = bcd_q[2];
    assign dig3  = bcd_q[3];
    assign dig4  = bcd_q[4];
    assign dig5  = bcd_q[5];
    assign dig6  = bcd_q[6];
    assign dig7  = bcd_q[7];
    assign dig8  = bcd_q[8];
    assign dig9  = bcd_q[9];
    assign dig10 = bcd_q[10];
endmodule
