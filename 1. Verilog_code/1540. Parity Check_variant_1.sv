//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module parity_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update,
    output reg [WIDTH-1:0] shadow_data,
    output reg parity_error
);
    // Registered input data
    reg [WIDTH-1:0] data_in_reg;
    reg update_reg;
    
    // Working register signals
    wire [WIDTH-1:0] work_reg;
    wire work_parity;
    
    // Shadow register parity
    reg shadow_parity;
    
    // Signals for borrow-propagate subtractor implementation
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // Register inputs first to reduce input to register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {WIDTH{1'b0}};
            update_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            update_reg <= update;
        end
    end
    
    // Move work_reg logic to combinational logic
    assign work_reg = update_reg ? data_in_reg : shadow_data;
    assign work_parity = ^work_reg;
    
    // Borrow-propagate subtractor logic
    // Start with no borrow
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: borrow_gen
            // Calculate borrow for next bit
            assign borrow[i+1] = (~work_reg[i] & shadow_data[i]) | 
                                 (~work_reg[i] & borrow[i]) | 
                                 (shadow_data[i] & borrow[i]);
            // Calculate difference
            assign diff[i] = work_reg[i] ^ shadow_data[i] ^ borrow[i];
        end
    endgenerate
    
    // Update shadow register and detect errors
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            shadow_parity <= 1'b0;
            parity_error <= 1'b0;
        end else if (update_reg) begin
            shadow_data <= work_reg;
            shadow_parity <= work_parity;
            parity_error <= work_parity != ^work_reg;
        end
    end
endmodule