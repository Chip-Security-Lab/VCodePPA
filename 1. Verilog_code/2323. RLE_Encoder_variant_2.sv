//SystemVerilog
module RLE_Encoder (
    input clk, rst_n, en,
    input [7:0] data_in,
    output reg [15:0] data_out,
    output reg req,     // 替换原来的valid信号
    input ack           // 新增应答信号
);
    // Pipeline stage 1: Data capture and comparison
    reg [7:0] prev_data_stage1;
    reg [7:0] counter_stage1;
    reg data_valid_stage1;
    reg [7:0] data_in_stage1;
    
    // Pipeline stage 2: Counter processing
    reg [7:0] prev_data_stage2;
    reg [7:0] counter_stage2;
    reg data_valid_stage2;
    reg counter_reset_stage2;
    
    // Pipeline stage 3: Output formation
    reg [7:0] prev_data_stage3;
    reg [7:0] counter_stage3;
    reg data_valid_stage3;
    
    // Request-Acknowledge handshake control
    reg output_ready;
    reg waiting_for_ack;
    
    // Stage 1: Data capture and comparison
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage1 <= 8'b0;
            counter_stage1 <= 8'b0;
            data_valid_stage1 <= 1'b0;
            data_in_stage1 <= 8'b0;
        end
        else if (en && (!waiting_for_ack || ack)) begin
            data_in_stage1 <= data_in;
            data_valid_stage1 <= 1'b1;
            
            if (data_in == prev_data_stage1 && counter_stage1 < 8'd255) begin
                counter_stage1 <= counter_stage1 + 8'b1;
            end
            else begin
                prev_data_stage1 <= data_in;
                counter_stage1 <= 8'b0;
            end
        end
        else begin
            data_valid_stage1 <= waiting_for_ack ? data_valid_stage1 : 1'b0;
        end
    end
    
    // Stage 2: Counter processing
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage2 <= 8'b0;
            counter_stage2 <= 8'b0;
            data_valid_stage2 <= 1'b0;
            counter_reset_stage2 <= 1'b0;
        end
        else if (!waiting_for_ack || ack) begin
            prev_data_stage2 <= prev_data_stage1;
            counter_stage2 <= counter_stage1;
            data_valid_stage2 <= data_valid_stage1;
            
            // Detect counter reset condition for output generation
            counter_reset_stage2 <= (data_in_stage1 != prev_data_stage1) || (counter_stage1 == 8'd255);
        end
    end
    
    // Stage 3: Output formation
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage3 <= 8'b0;
            counter_stage3 <= 8'b0;
            data_valid_stage3 <= 1'b0;
            data_out <= 16'b0;
            output_ready <= 1'b0;
        end
        else if (!waiting_for_ack || ack) begin
            prev_data_stage3 <= prev_data_stage2;
            counter_stage3 <= counter_stage2;
            data_valid_stage3 <= data_valid_stage2;
            
            // Generate output when counter reset is detected
            if (data_valid_stage2 && counter_reset_stage2) begin
                data_out <= {counter_stage2, prev_data_stage2};
                output_ready <= 1'b1;
            end
            else begin
                output_ready <= 1'b0;
            end
        end
    end
    
    // Request-Acknowledge handshake control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req <= 1'b0;
            waiting_for_ack <= 1'b0;
        end
        else begin
            if (output_ready && data_valid_stage3 && (counter_stage3 != 8'b0)) begin
                req <= 1'b1;
                waiting_for_ack <= 1'b1;
            end
            else if (waiting_for_ack && ack) begin
                req <= 1'b0;
                waiting_for_ack <= 1'b0;
            end
        end
    end
    
endmodule