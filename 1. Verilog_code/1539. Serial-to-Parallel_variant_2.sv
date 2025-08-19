//SystemVerilog
// IEEE 1364-2005 Verilog
module s2p_shadow_reg #(
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              serial_in,
    input  wire              shift_en,
    input  wire              capture,
    output reg  [WIDTH-1:0]  shadow_out,
    output wire [WIDTH-1:0]  parallel_out
);
    // Separate control signal registers for better timing
    reg serial_in_reg;
    reg shift_en_reg;
    reg capture_reg;
    
    // Shift register for serial-to-parallel conversion
    reg [WIDTH-1:0] shift_reg;
    
    // Registration of serial input signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            serial_in_reg <= 1'b0;
        else
            serial_in_reg <= serial_in;
    end
    
    // Registration of shift enable signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_en_reg <= 1'b0;
        else
            shift_en_reg <= shift_en;
    end
    
    // Registration of capture signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            capture_reg <= 1'b0;
        else
            capture_reg <= capture;
    end
    
    // Shift register operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {WIDTH{1'b0}};
        else if (shift_en_reg)
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in_reg};
    end
    
    // Shadow register update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else if (capture_reg)
            shadow_out <= shift_reg;
    end
    
    // Assign parallel output
    assign parallel_out = shift_reg;
    
endmodule