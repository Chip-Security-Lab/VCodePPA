//SystemVerilog
module bin2onehot #(parameter IN_WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire [IN_WIDTH-1:0] bin_in,
    output reg [(2**IN_WIDTH)-1:0] onehot_out
);

    // Stage 1: Register input
    reg [IN_WIDTH-1:0] bin_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_in_stage1 <= {IN_WIDTH{1'b0}};
        else
            bin_in_stage1 <= bin_in;
    end

    // Stage 2: Precompute shifted one-hot value to balance logic
    reg [(2**IN_WIDTH)-1:0] onehot_stage2;
    integer idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_stage2 <= {(2**IN_WIDTH){1'b0}};
        else begin
            onehot_stage2 <= {(2**IN_WIDTH){1'b0}};
            onehot_stage2[bin_in_stage1] <= 1'b1;
        end
    end

    // Stage 3: Register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_out <= {(2**IN_WIDTH){1'b0}};
        else
            onehot_out <= onehot_stage2;
    end

endmodule