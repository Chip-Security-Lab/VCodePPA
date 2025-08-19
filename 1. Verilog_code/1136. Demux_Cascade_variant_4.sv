//SystemVerilog
module Demux_Cascade #(parameter DW=8, DEPTH=2) (
    input clk,
    input [DW-1:0] data_in,
    input [$clog2(DEPTH+1)-1:0] addr,
    output [DEPTH:0][DW-1:0] data_out
);
    // Stage 1: Input registration
    reg [DW-1:0] data_in_stage1;
    reg [$clog2(DEPTH+1)-1:0] addr_stage1;
    reg stage1_valid;
    
    always @(posedge clk) begin
        data_in_stage1 <= data_in;
        addr_stage1 <= addr;
        stage1_valid <= 1'b1; // Always valid after reset
    end

    // Stage 2: Han-Carlson preprocessing
    reg [DW-1:0] p_stage2, g_stage2;
    reg [DW-1:0] data_in_stage2;
    reg [$clog2(DEPTH+1)-1:0] addr_stage2;
    reg stage2_valid;
    
    always @(posedge clk) begin
        // Propagate and generate signals
        p_stage2 <= data_in_stage1 | addr_stage1;
        g_stage2 <= data_in_stage1 & addr_stage1;
        // Forward required signals
        data_in_stage2 <= data_in_stage1;
        addr_stage2 <= addr_stage1;
        stage2_valid <= stage1_valid;
    end

    // Stage 3: Han-Carlson first prefix stage
    reg [DW-1:0] p_stage3, g_stage3;
    reg [DW-1:0] data_in_stage3;
    reg [$clog2(DEPTH+1)-1:0] addr_stage3;
    reg stage3_valid;
    
    always @(posedge clk) begin
        // Initialize with stage2 values
        p_stage3 <= p_stage2;
        g_stage3 <= g_stage2;
        
        // Process even bits
        for (int i = 2; i < DW; i = i + 2) begin
            p_stage3[i] <= p_stage2[i] & p_stage2[i-1];
            g_stage3[i] <= g_stage2[i] | (p_stage2[i] & g_stage2[i-1]);
        end
        
        // Forward required signals
        data_in_stage3 <= data_in_stage2;
        addr_stage3 <= addr_stage2;
        stage3_valid <= stage2_valid;
    end

    // Stage 4: Han-Carlson second prefix stage
    reg [DW-1:0] p_stage4, g_stage4;
    reg [DW-1:0] data_in_stage4;
    reg [$clog2(DEPTH+1)-1:0] addr_stage4;
    reg stage4_valid;
    
    always @(posedge clk) begin
        // Initialize with stage3 values
        p_stage4 <= p_stage3;
        g_stage4 <= g_stage3;
        
        // Process even bits further
        for (int i = 2; i < DW; i = i + 2) begin
            if (i > 0) begin
                p_stage4[i] <= p_stage3[i] & p_stage3[i-1];
                g_stage4[i] <= g_stage3[i] | (p_stage3[i] & g_stage3[i-1]);
            end
        end
        
        // Process odd bits now
        for (int i = 1; i < DW; i = i + 2) begin
            p_stage4[i] <= p_stage3[i] & p_stage3[i-1];
            g_stage4[i] <= g_stage3[i] | (p_stage3[i] & g_stage3[i-1]);
        end
        
        // Forward required signals
        data_in_stage4 <= data_in_stage3;
        addr_stage4 <= addr_stage3;
        stage4_valid <= stage3_valid;
    end

    // Stage 5: Demux logic part 1
    reg [DW-1:0] demux_data_stage5_0;
    reg [DW-1:0] data_in_stage5;
    reg [$clog2(DEPTH+1)-1:0] addr_stage5;
    reg [DW-1:0] g_stage5;
    reg stage5_valid;
    
    always @(posedge clk) begin
        // First demux output
        demux_data_stage5_0 <= (addr_stage4 == 0) ? data_in_stage4 : {DW{1'b0}};
        
        // Forward signals needed for next stages
        data_in_stage5 <= data_in_stage4;
        addr_stage5 <= addr_stage4;
        g_stage5 <= g_stage4;
        stage5_valid <= stage4_valid;
    end

    // Stage 6: Demux logic part 2 and output registration
    reg [DEPTH:0][DW-1:0] data_out_stage6;
    reg stage6_valid;
    
    always @(posedge clk) begin
        // First output from previous stage
        data_out_stage6[0] <= demux_data_stage5_0;
        
        // Compute remaining outputs
        for (int i = 1; i <= DEPTH; i = i + 1) begin
            if (addr_stage5 == i) begin
                data_out_stage6[i] <= data_in_stage5 ^ g_stage5[i[$clog2(DW)-1:0]];
            end else begin
                // Cascade from previous stage
                if (i == 1) begin
                    data_out_stage6[i] <= demux_data_stage5_0;
                end else begin
                    data_out_stage6[i] <= data_out_stage6[i-1];
                end
            end
        end
        
        stage6_valid <= stage5_valid;
    end

    // Final output assignment
    assign data_out = data_out_stage6;
    
endmodule