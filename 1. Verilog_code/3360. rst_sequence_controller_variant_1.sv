//SystemVerilog
module rst_sequence_controller (
    input  wire clk,
    input  wire main_rst_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);
    // Stage 1: Reset synchronization
    reg [1:0] main_rst_sync_stage1;
    reg sync_valid_stage1;
    
    // Stage 2: Counter control
    reg [2:0] seq_counter_stage2;
    reg sync_valid_stage2;
    
    // Stage 3: Output generation
    reg mem_rst_n_stage3;
    reg periph_rst_n_stage3;
    reg core_rst_n_stage3;
    
    // Stage 1: Reset synchronization
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            main_rst_sync_stage1 <= 2'b00;
            sync_valid_stage1 <= 1'b0;
        end else begin
            main_rst_sync_stage1 <= {main_rst_sync_stage1[0], 1'b1};
            sync_valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Counter control
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            seq_counter_stage2 <= 3'b000;
            sync_valid_stage2 <= 1'b0;
        end else begin
            sync_valid_stage2 <= sync_valid_stage1;
            if (sync_valid_stage1) begin
                if (main_rst_sync_stage1[1] && seq_counter_stage2 != 3'b111) begin
                    seq_counter_stage2 <= seq_counter_stage2 + 1;
                end
            end
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            mem_rst_n_stage3 <= 1'b0;
            periph_rst_n_stage3 <= 1'b0;
            core_rst_n_stage3 <= 1'b0;
        end else if (sync_valid_stage2) begin
            mem_rst_n_stage3 <= (seq_counter_stage2 >= 3'b001);
            periph_rst_n_stage3 <= (seq_counter_stage2 >= 3'b011);
            core_rst_n_stage3 <= (seq_counter_stage2 == 3'b111);
        end
    end
    
    // Output assignment
    assign mem_rst_n = mem_rst_n_stage3;
    assign periph_rst_n = periph_rst_n_stage3;
    assign core_rst_n = core_rst_n_stage3;
    
endmodule