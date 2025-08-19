//SystemVerilog
module johnson_counter #(parameter WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] johnson_code
);

    // Pipeline stage 1: Synchronous reset and enable control
    reg [WIDTH-1:0] johnson_stage1;
    wire reset_or_disable;

    assign reset_or_disable = ~rst_n | ~enable;

    always @(posedge clk) begin
        if (reset_or_disable)
            johnson_stage1 <= {WIDTH{1'b0}};
        else
            johnson_stage1 <= johnson_code;
    end

    // Pipeline stage 2: Johnson code update logic
    reg [WIDTH-1:0] johnson_stage2;

    always @(posedge clk) begin
        if (reset_or_disable)
            johnson_stage2 <= {WIDTH{1'b0}};
        else
            johnson_stage2 <= {~johnson_stage1[0], johnson_stage1[WIDTH-1:1]};
    end

    // Output register: Final pipeline stage for output
    always @(posedge clk) begin
        johnson_code <= johnson_stage2;
    end

endmodule