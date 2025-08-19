//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module priority_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_high_pri,
    input wire high_pri_valid,
    input wire [WIDTH-1:0] data_low_pri,
    input wire low_pri_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Register input signals to reduce input-to-register delay
    reg [WIDTH-1:0] data_high_pri_reg;
    reg [WIDTH-1:0] data_low_pri_reg;
    reg high_pri_valid_reg;
    reg low_pri_valid_reg;
    
    // Input registering stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_high_pri_reg <= {WIDTH{1'b0}};
            data_low_pri_reg <= {WIDTH{1'b0}};
            high_pri_valid_reg <= 1'b0;
            low_pri_valid_reg <= 1'b0;
        end else begin
            data_high_pri_reg <= data_high_pri;
            data_low_pri_reg <= data_low_pri;
            high_pri_valid_reg <= high_pri_valid;
            low_pri_valid_reg <= low_pri_valid;
        end
    end
    
    // Create priority vector with registered valid signals
    wire [1:0] priority_vector;
    assign priority_vector = {high_pri_valid_reg, low_pri_valid_reg};
    
    // Combinational selection logic (moved after register)
    wire [WIDTH-1:0] selected_data;
    assign selected_data = (priority_vector == 2'b10 || priority_vector == 2'b11) ? 
                           data_high_pri_reg : 
                           (priority_vector == 2'b01) ? data_low_pri_reg : shadow_out;
    
    // Combined shadow register update with direct data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else if (|priority_vector)
            shadow_out <= selected_data;
    end
    
endmodule