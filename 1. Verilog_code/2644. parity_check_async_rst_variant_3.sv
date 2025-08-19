//SystemVerilog
module parity_check_async_rst (
    input clk, arst,
    input [3:0] addr,
    input [7:0] data,
    input valid_in,
    output reg valid_out,
    output reg parity
);

    // Stage 1: First 4 bits XOR
    reg [1:0] stage1_result;
    reg valid_stage1;
    
    // Stage 2: Second 4 bits XOR
    reg [1:0] stage2_result;
    reg valid_stage2;

    // Stage 1 logic
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            stage1_result <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            // Calculate XOR of first 4 bits
            stage1_result <= {data[0] ^ data[1], data[2] ^ data[3]};
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2 logic
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            stage2_result <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            // Calculate XOR of last 4 bits
            stage2_result <= {data[4] ^ data[5], data[6] ^ data[7]};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final stage - combine results and generate parity
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            parity <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // Combine all XOR results and invert
            parity <= ~(stage1_result[0] ^ stage1_result[1] ^ stage2_result[0] ^ stage2_result[1]);
            valid_out <= valid_stage2;
        end
    end

endmodule