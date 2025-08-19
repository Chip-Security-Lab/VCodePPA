//SystemVerilog
module onehot_demux (
    input wire clk,                        // Pipeline clock
    input wire rst_n,                      // Active low reset
    input wire data_in,                    // Input data
    input wire [3:0] one_hot_sel,          // One-hot selection (only one bit active)
    output wire [3:0] data_out             // Output channels
);

    // Stage 1: Input Registering
    reg data_in_stage1;
    reg [3:0] one_hot_sel_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 1'b0;
            one_hot_sel_stage1 <= 4'b0000;
        end else begin
            data_in_stage1 <= data_in;
            one_hot_sel_stage1 <= one_hot_sel;
        end
    end

    // Stage 2: Data Replication and Selection
    reg [3:0] data_replicated_stage2;
    reg [3:0] one_hot_sel_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_replicated_stage2 <= 4'b0000;
            one_hot_sel_stage2 <= 4'b0000;
        end else begin
            data_replicated_stage2 <= {4{data_in_stage1}};
            one_hot_sel_stage2 <= one_hot_sel_stage1;
        end
    end

    // Stage 3: Output Registering for Data Out
    reg [3:0] data_out_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 4'b0000;
        end else begin
            data_out_stage3 <= data_replicated_stage2 & one_hot_sel_stage2;
        end
    end

    assign data_out = data_out_stage3;

endmodule