//SystemVerilog
module addr_trans_bridge #(parameter DWIDTH=32, AWIDTH=16) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [AWIDTH-1:0] dst_addr,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    // Configuration registers
    reg [AWIDTH-1:0] base_addr = 'h1000;  // Example base address
    reg [AWIDTH-1:0] limit_addr = 'h2000; // Example limit

    // Stage 1 registers (input stage)
    reg [AWIDTH-1:0] src_addr_stage1;
    reg [DWIDTH-1:0] src_data_stage1;
    reg valid_stage1;
    
    // Stage 2 registers (processing stage)
    reg [AWIDTH-1:0] addr_stage2;
    reg [DWIDTH-1:0] data_stage2;
    reg valid_stage2;
    reg in_range_stage2;
    
    // Pipeline control
    wire stage1_ready;
    wire stage2_ready;
    
    // Backward pressure handling
    assign stage2_ready = !valid_stage2 || dst_ready;
    assign stage1_ready = !valid_stage1 || stage2_ready;
    
    // Input stage ready signal
    always @(*) begin
        src_ready = stage1_ready;
    end
    
    // Stage 1: Input capture and buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_stage1 <= 0;
            src_data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            if (src_valid && src_ready) begin
                src_addr_stage1 <= src_addr;
                src_data_stage1 <= src_data;
                valid_stage1 <= 1;
            end else if (valid_stage1 && stage2_ready) begin
                valid_stage1 <= 0;
            end
        end
    end
    
    // Stage 2: Address translation and range checking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            data_stage2 <= 0;
            valid_stage2 <= 0;
            in_range_stage2 <= 0;
        end else begin
            if (valid_stage1 && stage2_ready) begin
                // Range check and address translation
                in_range_stage2 <= (src_addr_stage1 >= base_addr && src_addr_stage1 < limit_addr);
                addr_stage2 <= src_addr_stage1 - base_addr;
                data_stage2 <= src_data_stage1;
                valid_stage2 <= 1;
            end else if (valid_stage2 && dst_ready) begin
                valid_stage2 <= 0;
            end
        end
    end
    
    // Output stage: Generate output signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_addr <= 0;
            dst_data <= 0;
            dst_valid <= 0;
        end else begin
            if (valid_stage2 && dst_ready) begin
                dst_addr <= addr_stage2;
                dst_data <= data_stage2;
                dst_valid <= in_range_stage2;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 0;
            end
        end
    end
endmodule