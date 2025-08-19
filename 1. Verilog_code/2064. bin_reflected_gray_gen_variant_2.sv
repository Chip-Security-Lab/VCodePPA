//SystemVerilog
module bin_reflected_gray_gen #(parameter WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] gray_code,
    output reg valid
);

    // Stage 1: Counter and valid signal
    reg [WIDTH-1:0] counter_stage1;
    reg valid_stage1;

    // Stage 2: Pipeline register and valid signal
    reg [WIDTH-1:0] counter_stage2;
    reg valid_stage2;

    // Stage 2: Gray code computation
    reg [WIDTH-1:0] gray_code_stage2;

    // Optimized Stage 1: Counter logic with clear valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (enable) begin
                counter_stage1 <= counter_stage1 + {{(WIDTH-1){1'b0}}, 1'b1};
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // Optimized Stage 2: Pipeline register for counter and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Optimized Gray code computation using concatenation for efficiency
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_code_stage2 <= {WIDTH{1'b0}};
        end else begin
            gray_code_stage2 <= counter_stage2 ^ (counter_stage2 >> 1);
        end
    end

    // Optimized Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_code <= {WIDTH{1'b0}};
            valid <= 1'b0;
        end else begin
            gray_code <= gray_code_stage2;
            valid <= valid_stage2;
        end
    end

endmodule