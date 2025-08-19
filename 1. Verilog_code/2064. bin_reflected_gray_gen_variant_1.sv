//SystemVerilog
module bin_reflected_gray_gen #(parameter WIDTH = 4) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    output reg  [WIDTH-1:0]      gray_code
);

    // Pipeline stage 1: Counter register is merged with gray code combinational logic
    reg [WIDTH-1:0] counter_stage;
    reg [WIDTH-1:0] gray_stage;

    // Stage 1: Counter update and gray code combinational calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage <= {WIDTH{1'b0}};
            gray_stage    <= {WIDTH{1'b0}};
        end else if (enable) begin
            counter_stage <= counter_stage + 1'b1;
            gray_stage    <= (counter_stage + 1'b1) ^ ((counter_stage + 1'b1) >> 1);
        end
    end

    // Output register: Final gray code output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_code <= {WIDTH{1'b0}};
        end else if (enable) begin
            gray_code <= gray_stage;
        end
    end

endmodule