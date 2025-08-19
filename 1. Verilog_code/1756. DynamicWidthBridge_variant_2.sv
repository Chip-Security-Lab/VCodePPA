//SystemVerilog
module DynamicWidthBridge #(
    parameter IN_W = 32,
    parameter OUT_W = 64
)(
    input wire clk,
    input wire rst_n,
    input wire [IN_W-1:0] data_in,
    input wire in_valid,
    output wire [OUT_W-1:0] data_out,
    output wire out_valid
);

    // Design constants
    localparam RATIO = OUT_W / IN_W;
    localparam COUNT_WIDTH = $clog2(RATIO);
    
    // Pipeline stage 1 registers
    reg [OUT_W-1:0] data_buffer_stage1;
    reg [COUNT_WIDTH-1:0] counter_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers  
    reg [OUT_W-1:0] data_buffer_stage2;
    reg valid_stage2;
    reg data_ready_stage2;
    
    // Pipeline stage 3 registers
    reg [OUT_W-1:0] output_register;
    reg valid_stage3;

    // Stage 1: Input processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buffer_stage1 <= {OUT_W{1'b0}};
            counter_stage1 <= {COUNT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= in_valid;
            
            if (in_valid) begin
                data_buffer_stage1 <= {data_in, data_buffer_stage1[OUT_W-1:IN_W]};
                
                if (counter_stage1 == RATIO-1) begin
                    counter_stage1 <= {COUNT_WIDTH{1'b0}};
                end else begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
            end
        end
    end

    // Stage 2: Data ready generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buffer_stage2 <= {OUT_W{1'b0}};
            valid_stage2 <= 1'b0;
            data_ready_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            data_buffer_stage2 <= data_buffer_stage1;
            
            if (valid_stage1) begin
                data_ready_stage2 <= (counter_stage1 == RATIO-1);
            end else begin
                data_ready_stage2 <= 1'b0;
            end
        end
    end

    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_register <= {OUT_W{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2 && data_ready_stage2) begin
                output_register <= data_buffer_stage2;
            end
        end
    end

    // Output assignments
    assign data_out = output_register;
    assign out_valid = valid_stage3;

endmodule