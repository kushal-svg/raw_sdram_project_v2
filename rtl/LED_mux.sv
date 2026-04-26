module LED_mux (
    input  logic [5:0] in0,
    input  logic [5:0] in1,
    input  logic [5:0] in2,
    input  logic [5:0] in3,
    input  logic [5:0] in4,
    input  logic [5:0] in5,
    output logic [7:0] HEX0,
    output logic [7:0] HEX1,
    output logic [7:0] HEX2,
    output logic [7:0] HEX3,
    output logic [7:0] HEX4,
    output logic [7:0] HEX5
);
    function automatic logic [7:0] enc7(input logic [5:0] val);
        logic [7:0] seg;
        begin
            seg = 8'hFF; // all off (common-anode, active low)
            case (val[4:0])
                5'd0:  seg[6:0] = 7'b100_0000;
                5'd1:  seg[6:0] = 7'b111_1001;
                5'd2:  seg[6:0] = 7'b010_0100;
                5'd3:  seg[6:0] = 7'b011_0000;
                5'd4:  seg[6:0] = 7'b001_1001;
                5'd5:  seg[6:0] = 7'b001_0010;
                5'd6:  seg[6:0] = 7'b000_0010;
                5'd7:  seg[6:0] = 7'b111_1000;
                5'd8:  seg[6:0] = 7'b000_0000;
                5'd9:  seg[6:0] = 7'b001_0000;
                5'd10: seg[6:0] = 7'b000_1000; // A
                5'd11: seg[6:0] = 7'b000_0011; // b
                5'd12: seg[6:0] = 7'b100_0110; // C
                5'd13: seg[6:0] = 7'b010_0001; // d
                5'd14: seg[6:0] = 7'b000_0110; // E
                5'd15: seg[6:0] = 7'b000_1110; // F
                5'd16: seg[6:0] = 7'b100_0010; // G-ish
                5'd17: seg[6:0] = 7'b000_1001; // H
                5'd18: seg[6:0] = 7'b111_1001; // I ~ 1
                5'd19: seg[6:0] = 7'b110_0001; // J
                5'd20: seg[6:0] = 7'b100_0111; // L
                5'd21: seg[6:0] = 7'b100_0000; // O
                5'd22: seg[6:0] = 7'b000_1100; // P
                5'd23: seg[6:0] = 7'b100_1110; // r
                5'd24: seg[6:0] = 7'b001_0010; // S
                5'd25: seg[6:0] = 7'b100_0001; // U
                5'd26: seg[6:0] = 7'b001_0001; // y
                5'd27: seg[6:0] = 7'b010_0100; // Z ~ 2
                default: seg[6:0] = 7'b111_1111;
            endcase
            seg[7] = ~val[5];
            return seg;
        end
    endfunction

    always_comb begin
        HEX0 = enc7(in0);
        HEX1 = enc7(in1);
        HEX2 = enc7(in2);
        HEX3 = enc7(in3);
        HEX4 = enc7(in4);
        HEX5 = enc7(in5);
    end
endmodule
