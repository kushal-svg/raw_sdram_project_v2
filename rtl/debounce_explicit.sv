module debounce_explicit #(
    parameter int N = 21
) (
    input  logic clk,
    input  logic rst_n,
    input  logic sw,
    output logic db_level,
    output logic db_tick
);
    typedef enum logic [1:0] {IDLE, DELAY0, ONE, DELAY1} state_t;
    state_t state_q, state_d;
    logic [N-1:0] timer_q, timer_d;
    logic timer_zero, timer_inc, timer_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            timer_q <= '0;
        end else begin
            state_q <= state_d;
            timer_q <= timer_d;
        end
    end

    always_comb begin
        state_d    = state_q;
        timer_zero = 1'b0;
        timer_inc  = 1'b0;
        db_tick    = 1'b0;
        db_level   = 1'b0;

        case (state_q)
            IDLE: begin
                if (sw) begin
                    timer_zero = 1'b1;
                    state_d    = DELAY0;
                end
            end

            DELAY0: begin
                if (sw) begin
                    timer_inc = 1'b1;
                    if (timer_tick) begin
                        state_d = ONE;
                        db_tick = 1'b1;
                    end
                end else begin
                    state_d = IDLE;
                end
            end

            ONE: begin
                db_level = 1'b1;
                if (!sw) begin
                    timer_zero = 1'b1;
                    state_d    = DELAY1;
                end
            end

            DELAY1: begin
                db_level = 1'b1;
                if (!sw) begin
                    timer_inc = 1'b1;
                    if (timer_tick)
                        state_d = IDLE;
                end else begin
                    state_d = ONE;
                end
            end
        endcase
    end

    always_comb begin
        timer_d = timer_q;
        if (timer_zero)
            timer_d = '0;
        else if (timer_inc)
            timer_d = timer_q + 1'b1;

        timer_tick = (timer_q == {N{1'b1}});
    end
endmodule
