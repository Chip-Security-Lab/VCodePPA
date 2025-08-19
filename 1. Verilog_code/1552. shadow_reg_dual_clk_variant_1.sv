//SystemVerilog
module shadow_reg_dual_clk #(parameter DW=16) (
    input main_clk, shadow_clk,
    input load, 
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] shadow_storage;
    reg [DW-1:0] lut_out;
    
    // LUT for fast subtraction
    always @(*) begin
        case(din)
            8'h00: lut_out = 8'h00;
            8'h01: lut_out = 8'hFF;
            8'h02: lut_out = 8'hFE;
            8'h03: lut_out = 8'hFD;
            8'h04: lut_out = 8'hFC;
            8'h05: lut_out = 8'hFB;
            8'h06: lut_out = 8'hFA;
            8'h07: lut_out = 8'hF9;
            8'h08: lut_out = 8'hF8;
            8'h09: lut_out = 8'hF7;
            8'h0A: lut_out = 8'hF6;
            8'h0B: lut_out = 8'hF5;
            8'h0C: lut_out = 8'hF4;
            8'h0D: lut_out = 8'hF3;
            8'h0E: lut_out = 8'hF2;
            8'h0F: lut_out = 8'hF1;
            default: lut_out = din;
        endcase
    end
    
    // Main clock domain - merged logic with LUT
    always @(posedge main_clk) begin
        if(load) begin
            shadow_storage <= lut_out;
        end
    end
    
    // Shadow clock domain - simplified
    always @(posedge shadow_clk) begin
        dout <= shadow_storage;
    end
endmodule