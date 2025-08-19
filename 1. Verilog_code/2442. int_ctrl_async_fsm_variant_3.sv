//SystemVerilog
module int_ctrl_async_fsm #(parameter DW=4)(
    input wire clk,
    input wire rst_n, // Added reset signal for proper pipeline initialization
    input wire en,
    input wire [DW-1:0] int_req,
    output reg int_valid,
    output reg ready_for_next // Added ready signal for pipeline control
);

    // Pipeline stage registers
    reg [1:0] state_stage1;
    reg [1:0] state_stage2;
    reg [1:0] state_stage3;
    reg [DW-1:0] int_req_stage1;
    reg [DW-1:0] int_req_stage2;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;

    // Pipeline stage 1: Request detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= 2'd0;
            int_req_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en && ready_for_next) begin
            int_req_stage1 <= int_req;
            state_stage1 <= (|int_req) ? 2'd1 : 2'd0;
            valid_stage1 <= (|int_req) ? 1'b1 : 1'b0;
        end
    end

    // Pipeline stage 2: Validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= 2'd0;
            int_req_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (en) begin
            state_stage2 <= valid_stage1 ? 2'd2 : 2'd0;
            int_req_stage2 <= int_req_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3: Completion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= 2'd0;
            valid_stage3 <= 1'b0;
            int_valid <= 1'b0;
        end else if (en) begin
            state_stage3 <= valid_stage2 ? 2'd0 : 2'd0;
            valid_stage3 <= valid_stage2;
            int_valid <= valid_stage2;
        end
    end

    // Ready signal generation for pipeline flow control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_for_next <= 1'b1;
        end else begin
            // Ready when pipeline is not stalled
            ready_for_next <= !(valid_stage1 && valid_stage2 && valid_stage3);
        end
    end

endmodule