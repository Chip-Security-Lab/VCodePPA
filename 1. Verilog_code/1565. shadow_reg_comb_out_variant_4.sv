//SystemVerilog
// Top-level module
module shadow_reg_top #(parameter WIDTH=8) (
    input clk, 
    input en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    // Buffer for high fan-out input signal
    reg [WIDTH-1:0] din_buf1, din_buf2;
    
    always @(posedge clk) begin
        din_buf1 <= din;
        din_buf2 <= din;
    end
    
    // Instantiate the shadow register submodule
    shadow_reg #(WIDTH) reg_inst (
        .clk(clk),
        .en(en),
        .din_buf1(din_buf1),
        .din_buf2(din_buf2),
        .dout(dout)
    );
endmodule

// Shadow register submodule
module shadow_reg #(parameter WIDTH=8) (
    input clk, 
    input en,
    input [WIDTH-1:0] din_buf1,
    input [WIDTH-1:0] din_buf2,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] shadow_reg;
    reg [WIDTH-1:0] shadow_reg_buf1, shadow_reg_buf2;

    always @(posedge clk) begin
        if(en) shadow_reg <= din_buf1;
    end

    // Buffer for high fan-out shadow_reg signal
    always @(posedge clk) begin
        shadow_reg_buf1 <= shadow_reg;
        shadow_reg_buf2 <= shadow_reg;
    end

    always @(posedge clk) begin
        dout <= shadow_reg_buf1; // Update output using buffered signal
    end
endmodule