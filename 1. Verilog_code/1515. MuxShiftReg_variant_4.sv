//SystemVerilog
// IEEE 1364-2005 Verilog standard
module ShiftControl #(parameter DEPTH=4) (
    input [1:0] sel,
    output reg [DEPTH-1:0] shift_en
);
    always @(*) begin
        case(sel)
            2'b00: begin  // Shift left
                shift_en = {1'b1, {DEPTH-1{1'b0}}};
            end
            2'b01: begin  // Shift right
                shift_en = {{DEPTH-1{1'b0}}, 1'b1};
            end
            2'b10: begin  // Rotate right
                shift_en = {{DEPTH-1{1'b0}}, 1'b1};
            end
            default: begin // Hold
                shift_en = {DEPTH{1'b0}};
            end
        endcase
    end
endmodule

module RegisterArray #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input [DEPTH-1:0] shift_en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] regs [0:DEPTH-1];
    integer i;

    always @(posedge clk) begin
        for (i=0; i<DEPTH; i=i+1) begin
            if (shift_en[i]) begin
                if (i == 0) begin
                    regs[i] <= din;
                end else begin
                    regs[i] <= regs[i-1];
                end
            end
        end
        dout <= regs[DEPTH-1];
    end
endmodule

module MuxShiftReg #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input [1:0] sel,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    wire [DEPTH-1:0] shift_en;
    
    ShiftControl #(.DEPTH(DEPTH)) u_shift_control (
        .sel(sel),
        .shift_en(shift_en)
    );
    
    RegisterArray #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_reg_array (
        .clk(clk),
        .shift_en(shift_en),
        .din(din),
        .dout(dout)
    );
endmodule