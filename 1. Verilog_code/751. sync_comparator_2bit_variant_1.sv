//SystemVerilog
module sync_comparator_2bit_axi_lite (
    // AXI4-Lite Interface
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    // Internal registers
    reg [1:0] data_a_reg;
    reg [1:0] data_b_reg;
    reg eq_out_reg;
    reg gt_out_reg;
    reg lt_out_reg;
    
    // Address decoding - using one-hot encoding for faster address matching
    localparam [31:0] DATA_A_ADDR = 32'h0000_0000;
    localparam [31:0] DATA_B_ADDR = 32'h0000_0004;
    localparam [31:0] STATUS_ADDR = 32'h0000_0008;
    
    // One-hot address match signals
    wire is_data_a_addr = (AWADDR == DATA_A_ADDR);
    wire is_data_b_addr = (AWADDR == DATA_B_ADDR);
    wire is_status_addr = (ARADDR == STATUS_ADDR);
    
    // Write FSM states (Gray coding to reduce state transition glitches)
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b11;
    
    // Read FSM states (Gray coding)
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    reg [1:0] write_state, next_write_state;
    reg [1:0] read_state, next_read_state;
    
    // Optimized comparison signals using direct bit manipulation
    // For 2-bit values, we can optimize the comparison logic
    wire [1:0] diff = data_a_reg - data_b_reg;
    wire is_eq = (diff == 2'b00);
    wire is_gt = (data_a_reg[1] & ~data_b_reg[1]) | 
                 ((data_a_reg[1] == data_b_reg[1]) & (data_a_reg[0] & ~data_b_reg[0]));
    wire is_lt = ~is_eq & ~is_gt;
    
    // Next state logic for write FSM
    always @(*) begin
        next_write_state = write_state;
        
        case (write_state)
            WRITE_IDLE: begin
                if (AWVALID) next_write_state = WRITE_DATA;
            end
            
            WRITE_DATA: begin
                if (WVALID) next_write_state = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (BREADY) next_write_state = WRITE_IDLE;
            end
            
            default: next_write_state = WRITE_IDLE;
        endcase
    end
    
    // Next state logic for read FSM
    always @(*) begin
        next_read_state = read_state;
        
        case (read_state)
            READ_IDLE: begin
                if (ARVALID) next_read_state = READ_DATA;
            end
            
            READ_DATA: begin
                if (RREADY) next_read_state = READ_IDLE;
            end
            
            default: next_read_state = READ_IDLE;
        endcase
    end
    
    // Sequential logic for write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            data_a_reg <= 2'b00;
            data_b_reg <= 2'b00;
        end else begin
            write_state <= next_write_state;
            
            // Control signals for write channels
            AWREADY <= (next_write_state == WRITE_IDLE);
            WREADY <= (write_state == WRITE_DATA) && (next_write_state == WRITE_DATA || next_write_state == WRITE_RESP);
            BVALID <= (write_state == WRITE_RESP);
            
            // Data registers update
            if (write_state == WRITE_DATA && WVALID) begin
                if (is_data_a_addr) data_a_reg <= WDATA[1:0];
                else if (is_data_b_addr) data_b_reg <= WDATA[1:0];
            end
        end
    end
    
    // Sequential logic for read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
            RDATA <= 32'b0;
        end else begin
            read_state <= next_read_state;
            
            // Control signals for read channels
            ARREADY <= (next_read_state == READ_IDLE);
            RVALID <= (read_state == READ_DATA);
            
            // Read data logic
            if (read_state == READ_IDLE && ARVALID) begin
                case (ARADDR)
                    DATA_A_ADDR: begin
                        RDATA <= {30'b0, data_a_reg};
                        RRESP <= 2'b00;
                    end
                    DATA_B_ADDR: begin
                        RDATA <= {30'b0, data_b_reg};
                        RRESP <= 2'b00;
                    end
                    STATUS_ADDR: begin
                        RDATA <= {29'b0, lt_out_reg, gt_out_reg, eq_out_reg};
                        RRESP <= 2'b00;
                    end
                    default: begin
                        RDATA <= 32'b0;
                        RRESP <= 2'b11; // SLVERR
                    end
                endcase
            end
        end
    end
    
    // Comparison logic with registered outputs
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            eq_out_reg <= 1'b0;
            gt_out_reg <= 1'b0;
            lt_out_reg <= 1'b0;
        end else begin
            eq_out_reg <= is_eq;
            gt_out_reg <= is_gt;
            lt_out_reg <= is_lt;
        end
    end

endmodule