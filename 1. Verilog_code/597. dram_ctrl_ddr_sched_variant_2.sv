//SystemVerilog
module dram_ctrl_ddr_sched #(
    parameter CMD_QUEUE_DEPTH = 8
)(
    input clk,
    input rst_n,
    input [31:0] cmd_in,
    input cmd_valid,
    output reg cmd_ready,
    output reg [31:0] cmd_out,
    output reg cmd_out_valid
);

    // Pipeline stage 1: Command input and queue write
    reg [31:0] cmd_in_stage1;
    reg cmd_valid_stage1;
    reg [2:0] wr_ptr_stage1;
    reg [2:0] rd_ptr_stage1;
    reg [31:0] cmd_queue [0:CMD_QUEUE_DEPTH-1];
    
    // Pipeline stage 2: Queue read and output
    reg [31:0] cmd_out_stage2;
    reg cmd_out_valid_stage2;
    reg [2:0] wr_ptr_stage2;
    reg [2:0] rd_ptr_stage2;
    
    // Queue control signals
    wire queue_full_stage1, queue_empty_stage1;
    wire queue_full_stage2, queue_empty_stage2;
    
    assign queue_full_stage1 = ((wr_ptr_stage1 + 1) == rd_ptr_stage1);
    assign queue_empty_stage1 = (wr_ptr_stage1 == rd_ptr_stage1);
    assign queue_full_stage2 = ((wr_ptr_stage2 + 1) == rd_ptr_stage2);
    assign queue_empty_stage2 = (wr_ptr_stage2 == rd_ptr_stage2);

    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_in_stage1 <= 32'h0;
            cmd_valid_stage1 <= 1'b0;
        end else begin
            cmd_in_stage1 <= cmd_in;
            cmd_valid_stage1 <= cmd_valid;
        end
    end

    // Write pointer control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 3'h0;
        end else if (cmd_valid && !queue_full_stage1) begin
            wr_ptr_stage1 <= wr_ptr_stage1 + 1;
        end
    end

    // Queue write
    always @(posedge clk) begin
        if (cmd_valid && !queue_full_stage1) begin
            cmd_queue[wr_ptr_stage1] <= cmd_in;
        end
    end

    // Read pointer control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_stage1 <= 3'h0;
        end else if (!queue_empty_stage1) begin
            rd_ptr_stage1 <= rd_ptr_stage1 + 1;
        end
    end

    // Stage 2 pointer synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage2 <= 3'h0;
            rd_ptr_stage2 <= 3'h0;
        end else begin
            wr_ptr_stage2 <= wr_ptr_stage1;
            rd_ptr_stage2 <= rd_ptr_stage1;
        end
    end

    // Stage 2 output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_out_stage2 <= 32'h0;
            cmd_out_valid_stage2 <= 1'b0;
        end else begin
            if (!queue_empty_stage2) begin
                cmd_out_stage2 <= cmd_queue[rd_ptr_stage2];
                cmd_out_valid_stage2 <= 1'b1;
            end else begin
                cmd_out_valid_stage2 <= 1'b0;
            end
        end
    end

    // Output assignments
    always @(*) begin
        cmd_ready = !queue_full_stage1;
        cmd_out = cmd_out_stage2;
        cmd_out_valid = cmd_out_valid_stage2;
    end

endmodule