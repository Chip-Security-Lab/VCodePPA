//SystemVerilog, IEEE 1364-2005 standard
module eth_pkt_fifo #(
    parameter ADDR_WIDTH = 12,
    parameter PKT_MODE = 0  // 0: Cut-through, 1: Store-and-forward
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic [63:0]            wr_data,
    input  logic                   wr_en,
    input  logic                   wr_eop,
    output logic                   full,
    output logic [63:0]            rd_data,
    input  logic                   rd_en,
    output logic                   empty,
    output logic [ADDR_WIDTH-1:0]  pkt_count
);
    localparam DEPTH = 2**ADDR_WIDTH;
    
    // Memory declaration
    logic [63:0] mem [0:DEPTH-1];
    
    // Pointer registers with clear stages
    // Write path pointers
    logic [ADDR_WIDTH:0] wr_ptr;
    logic [ADDR_WIDTH:0] wr_ptr_next;
    logic [ADDR_WIDTH:0] pkt_wr_ptr;
    logic [ADDR_WIDTH:0] pkt_wr_ptr_next;
    
    // Read path pointers
    logic [ADDR_WIDTH:0] rd_ptr;
    logic [ADDR_WIDTH:0] rd_ptr_next;
    logic [ADDR_WIDTH:0] pkt_rd_ptr;
    logic [ADDR_WIDTH:0] pkt_rd_ptr_next;
    
    // Status signals with pipeline stages
    logic full_pre, empty_pre;
    
    // Write path pipeline registers
    logic wr_en_stage1;
    logic wr_eop_stage1;
    logic [63:0] wr_data_stage1;
    
    // Read path pipeline registers
    logic rd_en_stage1;
    logic [63:0] read_data;
    logic [63:0] read_data_pipe [0:2]; // 3-stage read data pipeline
    logic eop_detected;
    logic eop_detected_pipe;
    
    // Store-and-forward packet buffer
    logic [63:0] pkt_buffer [0:3];
    logic [63:0] pkt_buffer_stage [0:3];
    logic [1:0] read_idx;
    logic [1:0] read_idx_next;
    logic pkt_available;
    
    // Output data pipeline
    logic [63:0] fifo_data_pipe [0:1];
    
    // Memory initialization
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 64'h0;
        end
        wr_ptr = {(ADDR_WIDTH+1){1'b0}};
        rd_ptr = {(ADDR_WIDTH+1){1'b0}};
        pkt_wr_ptr = {(ADDR_WIDTH+1){1'b0}};
        pkt_rd_ptr = {(ADDR_WIDTH+1){1'b0}};
    end

    // ========== STAGE 1: Input Capture and Status Calculation ==========
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_en_stage1 <= 1'b0;
            rd_en_stage1 <= 1'b0;
            wr_eop_stage1 <= 1'b0;
            wr_data_stage1 <= 64'h0;
        end else begin
            wr_en_stage1 <= wr_en;
            rd_en_stage1 <= rd_en;
            wr_eop_stage1 <= wr_eop;
            wr_data_stage1 <= wr_data;
        end
    end
    
    // Pre-calculate FIFO status signals
    assign full_pre = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && 
                      (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]);
    assign empty_pre = (wr_ptr == rd_ptr);
    
    // Register status signals for timing improvement
    always_ff @(posedge clk) begin
        if (rst) begin
            full <= 1'b0;
            empty <= 1'b1;
        end else begin
            full <= full_pre;
            empty <= empty_pre;
        end
    end
    
    // ========== STAGE 2: Memory Write Operation ==========
    // Write pointer update logic with proper dependencies
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            pkt_wr_ptr <= 0;
        end else begin
            wr_ptr <= wr_ptr_next;
            pkt_wr_ptr <= pkt_wr_ptr_next;
        end
    end
    
    // Write operation and pointer calculation
    always_comb begin
        wr_ptr_next = wr_ptr;
        pkt_wr_ptr_next = pkt_wr_ptr;
        
        if (wr_en_stage1 && !full) begin
            wr_ptr_next = wr_ptr + 1'b1;
            if (wr_eop_stage1) begin
                pkt_wr_ptr_next = pkt_wr_ptr + 1'b1;
            end
        end
    end
    
    // Memory write operation
    always_ff @(posedge clk) begin
        if (wr_en_stage1 && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data_stage1;
        end
    end
    
    // ========== STAGE 3: Memory Read Operation ==========
    // Read pointer update logic
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            pkt_rd_ptr <= 0;
        end else begin
            rd_ptr <= rd_ptr_next;
            pkt_rd_ptr <= pkt_rd_ptr_next;
        end
    end
    
    // Read operation and pointer calculation
    always_comb begin
        rd_ptr_next = rd_ptr;
        pkt_rd_ptr_next = pkt_rd_ptr;
        
        if (rd_en_stage1 && !empty) begin
            rd_ptr_next = rd_ptr + 1'b1;
        end
        
        if (eop_detected_pipe) begin
            pkt_rd_ptr_next = pkt_rd_ptr + 1'b1;
        end
    end
    
    // Memory read operation with direct output to pipeline
    always_ff @(posedge clk) begin
        if (rd_en_stage1 && !empty) begin
            read_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            eop_detected <= (mem[rd_ptr[ADDR_WIDTH-1:0]][63:56] == 8'hFD);
        end else begin
            eop_detected <= 1'b0;
        end
    end
    
    // ========== STAGE 4: Read Data Pipeline ==========
    // Multi-stage read data pipeline for improved timing
    always_ff @(posedge clk) begin
        if (rst) begin
            read_data_pipe[0] <= 64'h0;
            read_data_pipe[1] <= 64'h0;
            read_data_pipe[2] <= 64'h0;
            eop_detected_pipe <= 1'b0;
        end else begin
            read_data_pipe[0] <= read_data;
            read_data_pipe[1] <= read_data_pipe[0];
            read_data_pipe[2] <= read_data_pipe[1];
            eop_detected_pipe <= eop_detected;
        end
    end
    
    // ========== STAGE 5: Packet Buffer and Mode Selection ==========
    // Packet buffer stage for store-and-forward mode
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                pkt_buffer[i] <= 64'h0;
                pkt_buffer_stage[i] <= 64'h0;
            end
            pkt_available <= 1'b0;
            read_idx <= 2'b0;
        end else begin
            // Packet available status
            pkt_available <= (pkt_rd_ptr != pkt_wr_ptr);
            read_idx <= read_idx_next;
            
            // For store-and-forward mode: load complete packet
            if (PKT_MODE == 1 && pkt_available) begin
                pkt_buffer[0] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b00}];
                pkt_buffer[1] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b01}];
                pkt_buffer[2] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b10}];
                pkt_buffer[3] <= mem[{pkt_rd_ptr[ADDR_WIDTH-3:0], 2'b11}];
                
                // Pipeline for better timing
                for (i = 0; i < 4; i = i + 1) begin
                    pkt_buffer_stage[i] <= pkt_buffer[i];
                end
            end
        end
    end
    
    // Read index calculation with proper dependency management
    always_comb begin
        read_idx_next = rd_ptr[1:0];
    end
    
    // ========== STAGE 6: Output Selection ==========
    // Final output pipeline and mode selection
    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_data_pipe[0] <= 64'h0;
            fifo_data_pipe[1] <= 64'h0;
        end else begin
            // Select data source based on mode
            if (PKT_MODE == 0) begin
                // Cut-through mode uses direct read pipeline
                fifo_data_pipe[0] <= read_data_pipe[1];
            end else begin
                // Store-and-forward mode uses packet buffer
                fifo_data_pipe[0] <= pkt_buffer_stage[read_idx];
            end
            
            // Final output stage
            fifo_data_pipe[1] <= fifo_data_pipe[0];
        end
    end
    
    // ========== Output Assignments ==========
    // Assign final output data
    assign rd_data = fifo_data_pipe[1];
    
    // Calculate packet count
    assign pkt_count = pkt_wr_ptr - pkt_rd_ptr;
    
endmodule