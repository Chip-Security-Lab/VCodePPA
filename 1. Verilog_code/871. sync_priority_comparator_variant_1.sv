//SystemVerilog
module sync_priority_comparator #(parameter WIDTH = 8)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out,
    output reg valid
);

    // Pipeline stage 1: Input registration and priority detection
    reg [WIDTH-1:0] data_in_reg;
    reg [$clog2(WIDTH)-1:0] priority_temp;
    reg valid_temp;

    // Pipeline stage 2: Output registration
    reg [$clog2(WIDTH)-1:0] priority_out_reg;
    reg valid_out_reg;

    // Priority encoder logic
    always @(*) begin
        priority_temp = 0;
        for (int i = WIDTH-1; i >= 0; i--) begin
            if (data_in_reg[i]) begin
                priority_temp = i[$clog2(WIDTH)-1:0];
            end
        end
        valid_temp = |data_in_reg;
    end

    // Pipeline stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
        end else begin
            data_in_reg <= data_in;
        end
    end

    // Pipeline stage 2: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out_reg <= 0;
            valid_out_reg <= 0;
        end else begin
            priority_out_reg <= priority_temp;
            valid_out_reg <= valid_temp;
        end
    end

    // Output assignment
    assign priority_out = priority_out_reg;
    assign valid = valid_out_reg;

endmodule