//SystemVerilog
module priority_buffer (
    input wire clk,
    input wire [7:0] data_a, data_b, data_c,
    input wire valid_a, valid_b, valid_c,
    output reg [7:0] data_out,
    output reg [1:0] source
);
    // Registered input data and valid signals
    reg [7:0] reg_data_a, reg_data_b, reg_data_c;
    reg reg_valid_a, reg_valid_b, reg_valid_c;
    
    // Combinational priority logic signals
    reg [7:0] next_data_out;
    reg [1:0] next_source;
    
    // Register input signals (backward retiming)
    always @(posedge clk) begin
        reg_data_a <= data_a;
        reg_data_b <= data_b;
        reg_data_c <= data_c;
        reg_valid_a <= valid_a;
        reg_valid_b <= valid_b;
        reg_valid_c <= valid_c;
    end
    
    // Optimized priority logic using combinational block
    always @(*) begin
        // Default values
        next_data_out = data_out;
        next_source = source;
        
        // Optimized priority encoding using case statement with priority
        casez ({reg_valid_a, reg_valid_b, reg_valid_c})
            3'b1??: begin // A has highest priority
                next_data_out = reg_data_a;
                next_source = 2'b00;
            end
            3'b01?: begin // B has second priority
                next_data_out = reg_data_b;
                next_source = 2'b01;
            end
            3'b001: begin // C has lowest priority
                next_data_out = reg_data_c;
                next_source = 2'b10;
            end
            // Default case implicitly handled by keeping previous values
        endcase
    end
    
    // Register outputs
    always @(posedge clk) begin
        data_out <= next_data_out;
        source <= next_source;
    end
endmodule