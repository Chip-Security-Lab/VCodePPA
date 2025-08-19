//SystemVerilog
module des_cbc_async (
    input wire clk,
    input wire rst_n,
    // Input interface - Valid/Ready
    input wire [63:0] din,
    input wire [63:0] iv,
    input wire [55:0] key,
    input wire valid_in,
    output wire ready_in,
    // Output interface - Valid/Ready
    output reg [63:0] dout,
    output reg valid_out,
    input wire ready_out
);
    // Internal signals and registers
    reg [63:0] xor_stage_reg;
    reg [63:0] feistel_out_reg;
    reg [63:0] feistel_input_reg;
    reg processing;
    reg processing_done;
    reg data_capture_valid;
    
    // Input handshaking logic
    assign ready_in = !processing || (valid_out && ready_out);
    
    // Processing state control - Reset Logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
        end
    end
    
    // Processing state control - Set Processing Flag
    always @(posedge clk) begin
        if (rst_n) begin
            if (valid_in && ready_in) begin
                processing <= 1'b1;
            end else if (valid_out && ready_out) begin
                processing <= 1'b0;
            end
        end
    end
    
    // Data capture stage
    always @(posedge clk) begin
        if (valid_in && ready_in) begin
            feistel_input_reg <= din ^ iv;
            data_capture_valid <= 1'b1;
        end else begin
            data_capture_valid <= 1'b0;
        end
    end
    
    // Feistel network - Stage 1
    always @(posedge clk) begin
        if (data_capture_valid) begin
            xor_stage_reg <= {feistel_input_reg[31:0], feistel_input_reg[63:32] ^ key[31:0]};
        end
    end
    
    // Feistel network - Stage 2
    always @(posedge clk) begin
        if (data_capture_valid) begin
            feistel_out_reg <= {xor_stage_reg[15:0], xor_stage_reg[63:16]};
            processing_done <= 1'b1;
        end else begin
            processing_done <= 1'b0;
        end
    end
    
    // Output data generation - Reset Logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            dout <= 64'b0;
        end
    end
    
    // Output data generation - Data Path
    always @(posedge clk) begin
        if (rst_n && processing_done) begin
            dout <= feistel_out_reg;
        end
    end
    
    // Output valid signal control - Reset Logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end
    end
    
    // Output valid signal control - Set/Clear Logic
    always @(posedge clk) begin
        if (rst_n) begin
            if (processing_done) begin
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule