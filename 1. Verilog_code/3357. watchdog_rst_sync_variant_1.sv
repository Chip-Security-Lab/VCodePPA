//SystemVerilog (IEEE 1364-2005)
module watchdog_rst_sync (
    input  wire clk,
    input  wire ext_rst_n,
    input  wire watchdog_trigger,
    output reg  combined_rst_n
);
    // 阶段1：外部复位同步信号
    reg [1:0] ext_rst_sync_stage1;
    reg       valid_stage1;
    
    // 阶段1：同步外部复位信号
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_sync_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            ext_rst_sync_stage1 <= {ext_rst_sync_stage1[0], 1'b1};
            valid_stage1 <= 1'b1;
        end
    end
    
    // 阶段1：看门狗触发信号同步
    reg watchdog_trigger_stage1;
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            watchdog_trigger_stage1 <= 1'b0;
        end else begin
            watchdog_trigger_stage1 <= watchdog_trigger;
        end
    end
    
    // 阶段2：外部复位同步信号传递
    reg [1:0] ext_rst_sync_stage2;
    reg       valid_stage2;
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_sync_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            ext_rst_sync_stage2 <= ext_rst_sync_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段2：看门狗复位生成
    reg watchdog_rst_n_stage2;
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            watchdog_rst_n_stage2 <= 1'b1;
        end else begin
            watchdog_rst_n_stage2 <= watchdog_trigger_stage1 ? 1'b0 : 1'b1;
        end
    end
    
    // 阶段3：最终复合复位生成
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            combined_rst_n <= 1'b0;
        end else if (valid_stage2) begin
            combined_rst_n <= ext_rst_sync_stage2[1] & watchdog_rst_n_stage2;
        end
    end
endmodule