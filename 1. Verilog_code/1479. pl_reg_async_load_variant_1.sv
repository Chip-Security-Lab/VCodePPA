//SystemVerilog
//IEEE 1364-2005 Verilog
module pl_reg_async_load #(parameter W=8) (
    input wire clk,       // Clock input
    input wire rst_n,     // Active-low asynchronous reset
    input wire load,      // Asynchronous load enable
    input wire [W-1:0] async_data,  // Data to load
    output wire [W-1:0] q  // Output register (changed from reg to wire)
);
    // Internal signals for retimed logic
    reg [W-1:0] data_reg;     // Register moved before output logic
    reg load_reg;             // Register to capture load signal
    
    // First stage: Register the input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {W{1'b0}};
            load_reg <= 1'b0;
        end else begin
            data_reg <= async_data;
            load_reg <= load;
        end
    end
    
    // Second stage: Output multiplexer logic
    // Moved the register backward through the selection logic
    reg [W-1:0] q_reg;
    
    always @(posedge clk or negedge rst_n or posedge load) begin
        if (!rst_n)
            q_reg <= {W{1'b0}};
        else if (load)
            q_reg <= async_data;  // Direct path for async load
        else
            q_reg <= data_reg;    // Normal registered path
    end
    
    // Assign the output
    assign q = q_reg;

endmodule