//SystemVerilog
// IEEE 1364-2005 Verilog
module s2p_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire serial_in,
    input wire shift_en,
    input wire capture,
    output reg [WIDTH-1:0] shadow_out,
    output wire [WIDTH-1:0] parallel_out
);
    // Main shift register
    reg [WIDTH-1:0] shift_reg;
    
    // Pipeline control signals
    reg shift_en_d1, shift_en_d2;
    reg capture_d1, capture_d2, capture_d3;
    
    // Pre-registered input
    reg serial_in_d1;
    
    // Pipelined shadow register data path
    reg [WIDTH-1:0] parallel_data_d1;
    reg [WIDTH-1:0] parallel_data_d2;
    
    // Register input signals (first stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_d1 <= 1'b0;
            shift_en_d1 <= 1'b0;
            capture_d1 <= 1'b0;
        end else begin
            serial_in_d1 <= serial_in;
            shift_en_d1 <= shift_en;
            capture_d1 <= capture;
        end
    end
    
    // Second stage control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_en_d2 <= 1'b0;
            capture_d2 <= 1'b0;
            capture_d3 <= 1'b0;
        end else begin
            shift_en_d2 <= shift_en_d1;
            capture_d2 <= capture_d1;
            capture_d3 <= capture_d2;
        end
    end
    
    // Main shift register operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WIDTH{1'b0}};
        end else if (shift_en_d1) begin
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in_d1};
        end
    end
    
    // Parallel data pipeline path (moved backward from output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_data_d1 <= {WIDTH{1'b0}};
            parallel_data_d2 <= {WIDTH{1'b0}};
        end else begin
            parallel_data_d1 <= shift_reg;
            parallel_data_d2 <= parallel_data_d1;
        end
    end
    
    // Shadow register with re-timed control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else if (capture_d3)
            shadow_out <= parallel_data_d2;
    end
    
    // Parallel output assignment
    assign parallel_out = parallel_data_d2;
    
endmodule