//SystemVerilog
module Timer_SyncLoad #(parameter WIDTH=8) (
    input clk, rst_n, enable,
    input [WIDTH-1:0] preset,
    output reg timeout
);
    // Stage 1: Counter logic
    reg [WIDTH-1:0] cnt_stage1;
    reg [WIDTH-1:0] preset_stage1;
    reg enable_stage1;
    reg compare_result_stage1;
    
    // Buffered copies of high fanout cnt_stage1 signal
    reg [WIDTH-1:0] cnt_stage1_buf1; // Buffer for comparison logic
    reg [WIDTH-1:0] cnt_stage1_buf2; // Buffer for increment logic
    
    // Stage 2: Timeout logic
    reg compare_result_stage2;
    
    // Buffer registers for high fanout signal cnt_stage1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1_buf1 <= 0;
            cnt_stage1_buf2 <= 0;
        end
        else begin
            cnt_stage1_buf1 <= cnt_stage1; // Buffer for comparison
            cnt_stage1_buf2 <= cnt_stage1; // Buffer for increment
        end
    end
    
    // Pipeline Stage 1: Counter and comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 0;
            preset_stage1 <= 0;
            enable_stage1 <= 0;
            compare_result_stage1 <= 0;
        end
        else begin
            preset_stage1 <= preset;
            enable_stage1 <= enable;
            
            if (enable_stage1)
                cnt_stage1 <= (cnt_stage1_buf1 == preset_stage1) ? 0 : cnt_stage1_buf2 + 1;
                
            compare_result_stage1 <= (cnt_stage1_buf1 == preset_stage1);
        end
    end
    
    // Pipeline Stage 2: Timeout output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compare_result_stage2 <= 0;
            timeout <= 0;
        end
        else begin
            compare_result_stage2 <= compare_result_stage1;
            timeout <= compare_result_stage2;
        end
    end
    
endmodule