//SystemVerilog
module triangle_wave_sync #(
    parameter DATA_WIDTH = 8
)(
    input clk_i,
    input sync_rst_i,
    input enable_i,
    output [DATA_WIDTH-1:0] wave_o
);
    // Stage 1: Direction Control
    reg up_down_stage1;
    reg [DATA_WIDTH-1:0] amplitude_stage1;
    reg enable_stage1;
    
    // Stage 2: Amplitude Update
    reg up_down_stage2;
    reg [DATA_WIDTH-1:0] amplitude_stage2;
    reg enable_stage2;
    
    // Stage 3: Output
    reg [DATA_WIDTH-1:0] amplitude_stage3;
    
    // Stage 1 Logic
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            up_down_stage1 <= 1'b1;
            amplitude_stage1 <= {DATA_WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable_i;
            amplitude_stage1 <= amplitude_stage3;
            
            if (enable_i) begin
                if (up_down_stage2 && &amplitude_stage2) begin
                    up_down_stage1 <= 1'b0;
                end else if (!up_down_stage2 && amplitude_stage2 == {DATA_WIDTH{1'b0}}) begin
                    up_down_stage1 <= 1'b1;
                end else begin
                    up_down_stage1 <= up_down_stage2;
                end
            end
        end
    end
    
    // Stage 2 Logic
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            up_down_stage2 <= 1'b1;
            amplitude_stage2 <= {DATA_WIDTH{1'b0}};
            enable_stage2 <= 1'b0;
        end else begin
            enable_stage2 <= enable_stage1;
            up_down_stage2 <= up_down_stage1;
            
            if (enable_stage1) begin
                if (up_down_stage1 && !(&amplitude_stage1)) begin
                    amplitude_stage2 <= amplitude_stage1 + 1'b1;
                end else if (!up_down_stage1 && amplitude_stage1 != {DATA_WIDTH{1'b0}}) begin
                    amplitude_stage2 <= amplitude_stage1 - 1'b1;
                end else begin
                    amplitude_stage2 <= amplitude_stage1;
                end
            end
        end
    end
    
    // Stage 3 Logic
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            amplitude_stage3 <= {DATA_WIDTH{1'b0}};
        end else begin
            amplitude_stage3 <= amplitude_stage2;
        end
    end
    
    // Output Assignment
    assign wave_o = amplitude_stage3;
endmodule