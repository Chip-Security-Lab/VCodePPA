//SystemVerilog
module therm_decoder (
    input clock,
    input reset_n,
    input [2:0] binary_in,
    input valid_in,
    output reg [7:0] therm_out,
    output reg valid_out,
    output reg ready_out
);

    // Pipeline registers
    reg [2:0] binary_stage1;
    reg valid_stage1;
    reg [7:0] therm_stage1;
    reg valid_stage2;
    reg ready_stage1;
    reg ready_stage2;
    
    // Stage 1: Input register
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            binary_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b1;
        end else begin
            if (ready_stage1) begin
                binary_stage1 <= binary_in;
                valid_stage1 <= valid_in;
            end
            ready_stage1 <= ready_stage2;
        end
    end
    
    // Stage 2: Optimized thermometer code generation
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            therm_stage1 <= 8'b0;
            valid_stage2 <= 1'b0;
            ready_stage2 <= 1'b1;
        end else begin
            if (ready_stage2) begin
                valid_stage2 <= valid_stage1;
                if (valid_stage1) begin
                    therm_stage1 <= (8'b1 << binary_stage1) - 1'b1;
                end
            end
            ready_stage2 <= 1'b1;
        end
    end
    
    // Stage 3: Output register
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            therm_out <= 8'b0;
            valid_out <= 1'b0;
            ready_out <= 1'b1;
        end else begin
            if (ready_out) begin
                therm_out <= therm_stage1;
                valid_out <= valid_stage2;
            end
        end
    end

endmodule