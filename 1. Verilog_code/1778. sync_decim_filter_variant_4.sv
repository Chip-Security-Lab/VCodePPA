//SystemVerilog
module sync_decim_filter #(
    parameter WIDTH = 8,
    parameter RATIO = 4
)(
    input clock, reset,
    input [WIDTH-1:0] in_data,
    input in_valid,
    output reg [WIDTH-1:0] out_data,
    output reg out_valid
);

    // Pipeline stage 1 - Input and counter control
    reg [$clog2(RATIO)-1:0] counter_stage1;
    reg [WIDTH-1:0] sum_stage1;
    reg in_valid_stage1;
    reg [WIDTH-1:0] in_data_stage1;
    
    // Pipeline stage 2 - Accumulation
    reg [$clog2(RATIO)-1:0] counter_stage2;
    reg [WIDTH-1:0] sum_stage2;
    reg in_valid_stage2;
    reg [WIDTH-1:0] in_data_stage2;
    
    // Pipeline stage 3 - Division and output
    reg [$clog2(RATIO)-1:0] counter_stage3;
    reg [WIDTH-1:0] sum_stage3;
    reg in_valid_stage3;
    
    // Control state registers
    reg [1:0] ctrl_state_stage1;
    reg [1:0] ctrl_state_stage2;
    reg [1:0] ctrl_state_stage3;

    // Stage 1 - Input and control logic
    always @(posedge clock) begin
        if (reset) begin
            ctrl_state_stage1 <= 2'b00;
            counter_stage1 <= 0;
            sum_stage1 <= 0;
            in_valid_stage1 <= 0;
            in_data_stage1 <= 0;
        end else begin
            in_valid_stage1 <= in_valid;
            in_data_stage1 <= in_data;
            
            if (in_valid) begin
                if (counter_stage1 == RATIO-1)
                    ctrl_state_stage1 <= 2'b01;
                else
                    ctrl_state_stage1 <= 2'b10;
            end else
                ctrl_state_stage1 <= 2'b11;
        end
    end

    // Stage 2 - Accumulation
    always @(posedge clock) begin
        if (reset) begin
            ctrl_state_stage2 <= 2'b00;
            counter_stage2 <= 0;
            sum_stage2 <= 0;
            in_valid_stage2 <= 0;
            in_data_stage2 <= 0;
        end else begin
            ctrl_state_stage2 <= ctrl_state_stage1;
            in_valid_stage2 <= in_valid_stage1;
            in_data_stage2 <= in_data_stage1;
            
            case (ctrl_state_stage1)
                2'b00: begin
                    counter_stage2 <= 0;
                    sum_stage2 <= 0;
                end
                2'b01: begin
                    counter_stage2 <= 0;
                    sum_stage2 <= 0;
                end
                2'b10: begin
                    sum_stage2 <= sum_stage1 + in_data_stage1;
                    counter_stage2 <= counter_stage1 + 1;
                end
                default: begin
                    counter_stage2 <= counter_stage1;
                    sum_stage2 <= sum_stage1;
                end
            endcase
        end
    end

    // Stage 3 - Division and output
    always @(posedge clock) begin
        if (reset) begin
            ctrl_state_stage3 <= 2'b00;
            counter_stage3 <= 0;
            sum_stage3 <= 0;
            in_valid_stage3 <= 0;
            out_valid <= 0;
            out_data <= 0;
        end else begin
            ctrl_state_stage3 <= ctrl_state_stage2;
            in_valid_stage3 <= in_valid_stage2;
            counter_stage3 <= counter_stage2;
            sum_stage3 <= sum_stage2;
            
            case (ctrl_state_stage2)
                2'b00: begin
                    out_valid <= 0;
                end
                2'b01: begin
                    out_data <= (sum_stage2 + in_data_stage2) / RATIO;
                    out_valid <= 1;
                end
                2'b10: begin
                    out_valid <= 0;
                end
                default: begin
                    out_valid <= 0;
                end
            endcase
        end
    end

endmodule