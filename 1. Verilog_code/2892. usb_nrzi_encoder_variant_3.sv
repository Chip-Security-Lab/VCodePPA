//SystemVerilog
//IEEE 1364-2005 Verilog
module usb_nrzi_encoder(
    input wire clk,
    input wire reset,
    input wire data_in,
    input wire valid_in,
    output reg data_out,
    output reg valid_out
);
    // Stage 1 registers - Input registration
    reg data_stage1;
    reg valid_stage1;
    
    // Stage 2 registers - NRZI state calculation
    reg valid_stage2;
    reg data_stage2;
    reg last_bit;
    
    // Stage 3 registers - NRZI bit generation
    reg next_bit_stage3;
    reg valid_stage3;
    
    // Stage 4 registers - Intermediate pipeline
    reg data_stage4;
    reg valid_stage4;
    
    // Stage 5 registers - Pre-output
    reg data_stage5;
    reg valid_stage5;

    // Stage 1: Input registration
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            if (valid_in) begin
                data_stage1 <= data_in;
            end
        end
    end
    
    // Stage 2: Data propagation and state preparation
    always @(posedge clk) begin
        if (reset) begin
            data_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            last_bit <= 1'b1;
        end else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            if (valid_stage1 && data_stage1 == 1'b1) begin
                // No change to last_bit for '1' bits, only propagate
            end else if (valid_stage1 && data_stage1 == 1'b0) begin
                // Invert last_bit for '0' bits
                last_bit <= ~last_bit;
            end
        end
    end
    
    // Stage 3: NRZI encoding calculation
    always @(posedge clk) begin
        if (reset) begin
            next_bit_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                if (data_stage2 == 1'b0) begin
                    // For '0' input bits, next bit is the inverted last bit
                    next_bit_stage3 <= ~last_bit;
                end else begin
                    // For '1' input bits, next bit is same as last bit
                    next_bit_stage3 <= last_bit;
                end
            end
        end
    end
    
    // Stage 4: Intermediate pipeline stage
    always @(posedge clk) begin
        if (reset) begin
            data_stage4 <= 1'b1;
            valid_stage4 <= 1'b0;
        end else begin
            data_stage4 <= next_bit_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Stage 5: Pre-output stage
    always @(posedge clk) begin
        if (reset) begin
            data_stage5 <= 1'b1;
            valid_stage5 <= 1'b0;
        end else begin
            data_stage5 <= data_stage4;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Final output: data signal
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 1'b1;
        end else begin
            data_out <= data_stage5;
        end
    end
    
    // Final output: valid signal
    always @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage5;
        end
    end
endmodule