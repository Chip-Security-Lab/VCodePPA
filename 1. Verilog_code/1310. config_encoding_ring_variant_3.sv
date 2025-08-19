//SystemVerilog
module config_encoding_ring #(
    parameter ENCODING = "ONEHOT" // or "BINARY"
)(
    input wire clk, rst,
    input wire enable,
    output reg [3:0] code_out,
    output reg valid_out
);

    // Pipeline stage 1 signals
    reg [3:0] code_stage1;
    reg valid_stage1;
    reg [3:0] next_code;
    
    // Pipeline stage 2 signals
    reg [3:0] code_stage2;
    reg valid_stage2;

    // Stage 1: Calculate next code value
    always @(*) begin
        if (ENCODING == "ONEHOT") begin
            next_code = {code_out[0], code_out[3:1]};
        end else if (ENCODING == "BINARY") begin
            if (code_out == 4'b1000) begin
                next_code = 4'b0001;
            end else begin
                next_code = code_out << 1;
            end
        end else begin
            next_code = code_out;
        end
    end
    
    // Pipeline stage 1 registers
    always @(posedge clk) begin
        if (rst) begin
            if (ENCODING == "ONEHOT") begin
                code_stage1 <= 4'b0001;
            end else begin
                code_stage1 <= 4'b0000;
            end
            valid_stage1 <= 1'b0;
        end else begin
            if (enable) begin
                code_stage1 <= next_code;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2 registers
    always @(posedge clk) begin
        if (rst) begin
            code_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            code_stage2 <= code_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage registers
    always @(posedge clk) begin
        if (rst) begin
            code_out <= 4'b0000;
            valid_out <= 1'b0;
        end else begin
            code_out <= code_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule