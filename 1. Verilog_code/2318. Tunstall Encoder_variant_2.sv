//SystemVerilog
module tunstall_encoder #(
    parameter CODEWORD_WIDTH = 4
)(
    input                         clk_i,
    input                         enable_i,
    input                         rst_i,
    input      [7:0]              data_i,
    input                         data_valid_i,
    output reg [CODEWORD_WIDTH-1:0] code_o,
    output reg                    code_valid_o
);
    // Simplified Tunstall implementation with predefined dictionary
    reg [7:0] buffer;
    reg       buffer_valid;
    reg       process_data;
    
    // Buffer management logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            buffer <= 8'b0;
            buffer_valid <= 1'b0;
        end else if (enable_i && data_valid_i && !buffer_valid) begin
            buffer <= data_i;
            buffer_valid <= 1'b1;
        end else if (process_data) begin
            buffer <= 8'b0;
            buffer_valid <= 1'b0;
        end
    end
    
    // Process data control logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            process_data <= 1'b0;
        end else begin
            process_data <= enable_i && data_valid_i && buffer_valid;
        end
    end
    
    // Code generation logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            code_o <= {CODEWORD_WIDTH{1'b0}};
        end else if (process_data) begin
            // Map two bytes to one codeword (simplified)
            case ({buffer[1:0], data_i[1:0]})
                4'b0000: code_o <= 4'h0;
                4'b0001: code_o <= 4'h1;
                // ... other combinations ...
                default: code_o <= 4'hF;
            endcase
        end
    end
    
    // Code valid signal logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            code_valid_o <= 1'b0;
        end else if (process_data) begin
            code_valid_o <= 1'b1;
        end else begin
            code_valid_o <= 1'b0;
        end
    end
    
endmodule