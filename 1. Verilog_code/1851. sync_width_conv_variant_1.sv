//SystemVerilog
module sync_width_conv #(parameter IN_W=8, OUT_W=16, DEPTH=4) (
    input clk, rst_n,
    input [IN_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output reg [OUT_W-1:0] dout
);
    localparam CNT_W = $clog2(DEPTH);
    
    // Memory buffer
    reg [IN_W-1:0] buffer[0:DEPTH-1];
    
    // Pointers with reduced fan-out implementation
    reg [CNT_W:0] wr_ptr = 0, rd_ptr = 0;
    
    // Buffered pointers for different consumers to reduce fan-out
    reg [CNT_W:0] wr_ptr_buff1 = 0, wr_ptr_buff2 = 0;
    reg [CNT_W:0] rd_ptr_buff1 = 0, rd_ptr_buff2 = 0;
    
    // Buffer address signals with lower fan-out
    reg [CNT_W-1:0] wr_addr = 0;
    reg [CNT_W-1:0] rd_addr = 0, rd_addr_next = 0;
    
    // Pipeline control signals
    reg valid_stage1 = 0, valid_stage2 = 0;
    reg rd_en_stage1 = 0, rd_en_stage2 = 0;
    reg [IN_W-1:0] data_stage1 = 0, data_stage2 = 0;
    reg [CNT_W-1:0] addr_stage1 = 0, addr_stage2 = 0;
    reg [CNT_W-1:0] addr_next_stage1 = 0, addr_next_stage2 = 0;
    
    // Update write pointer logic with buffers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            wr_ptr_buff1 <= 0;
            wr_ptr_buff2 <= 0;
            wr_addr <= 0;
        end
        else begin
            // Buffer the write pointer for different consumers
            wr_ptr_buff1 <= wr_ptr;
            wr_ptr_buff2 <= wr_ptr;
            
            // Extract and buffer the write address
            wr_addr <= wr_ptr[CNT_W-1:0];
            
            if (wr_en && !full) begin
                buffer[wr_addr] <= din;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end
    
    // Pipeline Stage 1: Read address calculation and data fetch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
            rd_en_stage1 <= 0;
            data_stage1 <= 0;
            addr_stage1 <= 0;
            addr_next_stage1 <= 0;
        end
        else begin
            valid_stage1 <= rd_en && !empty;
            rd_en_stage1 <= rd_en;
            
            if (rd_en && !empty) begin
                addr_stage1 <= rd_ptr[CNT_W-1:0];
                addr_next_stage1 <= rd_ptr[CNT_W-1:0] + 1;
                data_stage1 <= buffer[rd_ptr[CNT_W-1:0]];
            end
        end
    end
    
    // Pipeline Stage 2: Data combination and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
            rd_en_stage2 <= 0;
            data_stage2 <= 0;
            addr_stage2 <= 0;
            addr_next_stage2 <= 0;
            dout <= 0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            rd_en_stage2 <= rd_en_stage1;
            data_stage2 <= data_stage1;
            addr_stage2 <= addr_stage1;
            addr_next_stage2 <= addr_next_stage1;
            
            if (valid_stage1) begin
                dout <= {buffer[addr_next_stage1], data_stage1};
            end
        end
    end
    
    // Update read pointer logic with buffers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rd_ptr_buff1 <= 0;
            rd_ptr_buff2 <= 0;
        end
        else begin
            // Buffer the read pointer for different consumers
            rd_ptr_buff1 <= rd_ptr;
            rd_ptr_buff2 <= rd_ptr;
            
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 2;
            end
        end
    end
    
    // Use buffered pointers for status flags to reduce fan-out
    assign full = (wr_ptr_buff1 - rd_ptr_buff1) >= DEPTH;
    assign empty = (wr_ptr_buff2 == rd_ptr_buff2);
    
endmodule