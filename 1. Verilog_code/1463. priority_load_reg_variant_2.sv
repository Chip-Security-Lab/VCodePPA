//SystemVerilog
module priority_load_reg (
    input wire clk,
    input wire rst_n,
    
    // Input data paths
    input wire [7:0] data_a,  // Highest priority data
    input wire [7:0] data_b,  // Medium priority data
    input wire [7:0] data_c,  // Lowest priority data
    
    // Load control signals
    input wire load_a,        // Highest priority load control
    input wire load_b,        // Medium priority load control
    input wire load_c,        // Lowest priority load control
    
    // Output result
    output reg [7:0] result
);

    // Input registers with one-hot encoding for priority control
    reg [7:0] data_a_reg, data_b_reg, data_c_reg;
    reg [2:0] load_priority;  // One-hot encoded priority signals
    
    // Stage 1: Register inputs with optimized structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg <= 8'h00;
            data_b_reg <= 8'h00;
            data_c_reg <= 8'h00;
            load_priority <= 3'b000;
        end
        else begin
            data_a_reg <= data_a;
            data_b_reg <= data_b;
            data_c_reg <= data_c;
            
            // Convert load signals to one-hot priority encoding
            // Only highest priority bit is set if multiple loads are active
            load_priority[2] <= load_a;
            load_priority[1] <= load_b & ~load_a;
            load_priority[0] <= load_c & ~load_a & ~load_b;
        end
    end
    
    // Stage 2: Optimized priority selection using one-hot encoding
    reg [7:0] next_result;
    wire valid_load;
    
    assign valid_load = |load_priority;
    
    always @(*) begin
        case (load_priority)
            3'b100, 3'b101, 3'b110, 3'b111: next_result = data_a_reg;  // load_a is active
            3'b010, 3'b011:                 next_result = data_b_reg;  // load_b is active, load_a inactive
            3'b001:                         next_result = data_c_reg;  // only load_c is active
            default:                        next_result = result;      // keep current value
        endcase
    end
    
    // Stage 3: Output register update with optimized control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'h00;
        end
        else if (valid_load) begin
            result <= next_result;
        end
    end

endmodule