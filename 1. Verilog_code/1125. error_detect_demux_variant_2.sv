//SystemVerilog
module error_detect_demux (
    input wire clk,                      // Clock signal
    input wire rst_n,                    // Active-low reset
    input wire data_in,                  // Input data
    input wire [2:0] address_in,         // Address selection
    output wire [4:0] data_out,          // Output lines
    output wire error_flag               // Error indication
);

    // Pipeline registers for improved timing
    reg data_r1;
    reg [2:0] address_r1;
    reg address_valid_r1;
    
    // Intermediate buffered registers for high fanout signals
    reg [4:0] data_out_r;
    reg error_flag_r;
    
    // Additional buffer registers for output data (reducing fanout)
    reg [4:0] data_out_buf;
    reg error_flag_buf;
    
    // First pipeline stage: Input capture and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r1 <= 1'b0;
            address_r1 <= 3'b000;
            address_valid_r1 <= 1'b0;
        end else begin
            data_r1 <= data_in;
            address_r1 <= address_in;
            address_valid_r1 <= (address_in < 3'd5) ? 1'b1 : 1'b0;
        end
    end
    
    // Second pipeline stage: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_r <= 5'b00000;
            error_flag_r <= 1'b0;
        end else begin
            data_out_r <= 5'b00000;  // Default all outputs to zero
            
            if (address_valid_r1) begin
                // Valid data path - route to correct output
                data_out_r[address_r1] <= data_r1;
                error_flag_r <= 1'b0;
            end else begin
                // Error path - invalid address
                data_out_r <= 5'b00000;
                error_flag_r <= data_r1;
            end
        end
    end
    
    // Output buffer stage to reduce fanout load
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_buf <= 5'b00000;
            error_flag_buf <= 1'b0;
        end else begin
            data_out_buf <= data_out_r;
            error_flag_buf <= error_flag_r;
        end
    end
    
    // Assign buffered outputs to module ports
    assign data_out = data_out_buf;
    assign error_flag = error_flag_buf;

endmodule