//SystemVerilog
module manchester_encoder_axi4lite (
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
    input wire RREADY,
    
    // Manchester Encoder Output
    output reg encoded
);

    // Internal registers
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    reg clk_div;
    
    // Address decoding - use localparam for better synthesis
    localparam CONTROL_REG_ADDR = 32'h0000_0000;
    localparam STATUS_REG_ADDR = 32'h0000_0004;
    
    // Pre-decode address signals to reduce critical path
    wire is_control_reg_addr = (AWADDR == CONTROL_REG_ADDR);
    wire is_status_reg_addr = (ARADDR == STATUS_REG_ADDR);
    wire is_control_reg_addr_read = (ARADDR == CONTROL_REG_ADDR);
    
    // Write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    reg [1:0] write_state, write_next_state;
    
    // Read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    reg [1:0] read_state, read_next_state;
    
    // Prefetch the next state logic to balance paths
    always @(*) begin
        // Default assignments to avoid latches
        write_next_state = write_state;
        
        case (write_state)
            WRITE_IDLE: begin
                if (AWVALID && WVALID) 
                    write_next_state = WRITE_DATA;
            end
            WRITE_DATA: begin
                write_next_state = WRITE_RESP;
            end
            WRITE_RESP: begin
                if (BREADY)
                    write_next_state = WRITE_IDLE;
            end
            default: write_next_state = WRITE_IDLE;
        endcase
    end
    
    // Write FSM - sequential logic only
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            control_reg <= 32'h0;
        end else begin
            write_state <= write_next_state;
            
            // Default assignments
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            
            case (write_state)
                WRITE_IDLE: begin
                    if (AWVALID && WVALID) begin
                        AWREADY <= 1'b1;
                        WREADY <= 1'b1;
                    end
                end
                WRITE_DATA: begin
                    if (is_control_reg_addr) begin
                        control_reg <= WDATA;
                    end
                    BVALID <= 1'b1;
                    BRESP <= 2'b00;
                end
                WRITE_RESP: begin
                    if (BREADY) begin
                        BVALID <= 1'b0;
                    end else begin
                        BVALID <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // Prefetch read next state logic
    always @(*) begin
        // Default assignments
        read_next_state = read_state;
        
        case (read_state)
            READ_IDLE: begin
                if (ARVALID)
                    read_next_state = READ_DATA;
            end
            READ_DATA: begin
                if (RREADY)
                    read_next_state = READ_IDLE;
            end
            default: read_next_state = READ_IDLE;
        endcase
    end
    
    // Read data mux - separated to reduce critical path
    reg [31:0] read_data_mux;
    always @(*) begin
        if (is_control_reg_addr_read)
            read_data_mux = control_reg;
        else if (is_status_reg_addr)
            read_data_mux = status_reg;
        else
            read_data_mux = 32'h0;
    end
    
    // Read FSM - sequential logic only
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
            RDATA <= 32'h0;
        end else begin
            read_state <= read_next_state;
            
            // Default assignments
            ARREADY <= 1'b0;
            
            case (read_state)
                READ_IDLE: begin
                    if (ARVALID) begin
                        ARREADY <= 1'b1;
                    end
                end
                READ_DATA: begin
                    RVALID <= 1'b1;
                    RRESP <= 2'b00;
                    RDATA <= read_data_mux;
                    
                    if (RREADY) begin
                        RVALID <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    // Manchester Encoder Logic - optimized for timing
    wire next_encoded = control_reg[0] ^ clk_div;
    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            clk_div <= 1'b0;
            encoded <= 1'b0;
            status_reg <= 32'h0;
        end else begin
            clk_div <= ~clk_div;
            encoded <= next_encoded;
            status_reg <= {31'b0, next_encoded}; // Pre-compute status register
        end
    end

endmodule