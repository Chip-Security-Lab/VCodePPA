//SystemVerilog
module parity_reg (
    input           clk,
    input           reset,
    input  [7:0]    data,
    input           load,
    output [8:0]    data_with_parity
);

    // Internal pipeline registers
    reg    [7:0]    data_stage1;
    reg             load_stage1;
    reg    [7:0]    data_stage2;
    reg             parity_bit;
    reg    [8:0]    data_with_parity_reg;
    
    // Fanout buffers for high fan-out signals
    reg    [7:0]    data_stage1_buf1, data_stage1_buf2;
    reg             parity_bit_buf1, parity_bit_buf2;
    reg             b0_buf1, b0_buf2;  // Buffer for potential bit 0 usage
    
    // Stage 1: Data capture and pipeline control
    always @(posedge clk) begin
        if (reset) begin
            data_stage1  <= 8'b0;
            load_stage1  <= 1'b0;
        end
        else begin
            data_stage1  <= data;
            load_stage1  <= load;
        end
    end
    
    // Buffer registers for data_stage1 to reduce fan-out
    always @(posedge clk) begin
        if (reset) begin
            data_stage1_buf1 <= 8'b0;
            data_stage1_buf2 <= 8'b0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
        end
        else begin
            data_stage1_buf1 <= data_stage1;
            data_stage1_buf2 <= data_stage1;
            b0_buf1 <= data_stage1[0];
            b0_buf2 <= data_stage1[0];
        end
    end

    // Stage 2: Parity calculation (using buffered signals)
    always @(posedge clk) begin
        if (reset) begin
            data_stage2  <= 8'b0;
            parity_bit   <= 1'b0;
        end
        else if (load_stage1) begin
            data_stage2  <= data_stage1_buf1;
            parity_bit   <= ^data_stage1_buf2; // Use buffered copy for parity calculation
        end
    end
    
    // Buffer registers for parity_bit to reduce fan-out
    always @(posedge clk) begin
        if (reset) begin
            parity_bit_buf1 <= 1'b0;
            parity_bit_buf2 <= 1'b0;
        end
        else begin
            parity_bit_buf1 <= parity_bit;
            parity_bit_buf2 <= parity_bit;
        end
    end

    // Final stage: Output register
    always @(posedge clk) begin
        if (reset) begin
            data_with_parity_reg <= 9'b0;
        end
        else begin
            data_with_parity_reg <= {parity_bit_buf1, data_stage2};
        end
    end

    // Connect to output
    assign data_with_parity = data_with_parity_reg;

endmodule