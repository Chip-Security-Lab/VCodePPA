//SystemVerilog
// Top-level module with AXI4-Lite interface
module Segmented_XNOR (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    
    // AXI4-Lite write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    
    // AXI4-Lite write response channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    
    // AXI4-Lite read data channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal registers for AXI operation
    reg [7:0] high_reg;
    reg [7:0] low_reg;
    reg [7:0] res_reg;
    
    // AXI FSM states
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    
    // AXI control signals
    reg awready_reg, wready_reg, bvalid_reg;
    reg arready_reg, rvalid_reg;
    reg [31:0] rdata_reg;
    
    // Address decoding - registers are at 4-byte boundaries
    localparam ADDR_HIGH = 4'h0; // 0x00
    localparam ADDR_LOW = 4'h4;  // 0x04
    localparam ADDR_RES = 4'h8;  // 0x08
    
    // Core computation logic
    wire [3:0] high_upper = high_reg[7:4];
    wire [3:0] high_lower = high_reg[3:0];
    wire [3:0] low_upper = low_reg[7:4];
    wire [3:0] low_lower = low_reg[3:0];
    wire [3:0] res_upper, res_lower;

    // Instantiate XNOR_Segment for upper bits calculation
    XNOR_Segment upper_segment (
        .a(high_upper),
        .b(low_lower),
        .result(res_upper)
    );

    // Instantiate XNOR_Segment for lower bits calculation
    XNOR_Segment lower_segment (
        .a(high_lower),
        .b(low_upper),
        .result(res_lower)
    );

    // Combine results
    wire [7:0] res_computed = {res_upper, res_lower};
    
    // Update result register whenever inputs change
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            res_reg <= 8'h00;
        end else begin
            res_reg <= res_computed;
        end
    end
    
    // AXI Write Channel FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            write_state <= IDLE;
            awready_reg <= 1'b0;
            wready_reg <= 1'b0;
            bvalid_reg <= 1'b0;
            high_reg <= 8'h00;
            low_reg <= 8'h00;
        end else begin
            write_state <= write_next;
            
            // Handle write address ready
            if (write_state == IDLE && s_axi_awvalid) begin
                awready_reg <= 1'b1;
            end else begin
                awready_reg <= 1'b0;
            end
            
            // Handle write data ready
            if (write_state == WRITE && s_axi_wvalid) begin
                wready_reg <= 1'b1;
                
                // Write to appropriate register
                case (s_axi_awaddr[5:2])
                    ADDR_HIGH: if (s_axi_wstrb[0]) high_reg <= s_axi_wdata[7:0];
                    ADDR_LOW: if (s_axi_wstrb[0]) low_reg <= s_axi_wdata[7:0];
                    // Result register is read-only
                    default: ; // Do nothing
                endcase
            end else begin
                wready_reg <= 1'b0;
            end
            
            // Handle write response
            if (write_state == RESP) begin
                bvalid_reg <= 1'b1;
            end else if (s_axi_bready && bvalid_reg) begin
                bvalid_reg <= 1'b0;
            end
        end
    end
    
    // AXI Write Channel Next State Logic
    always @(*) begin
        write_next = write_state;
        
        case (write_state)
            IDLE: if (s_axi_awvalid) write_next = WRITE;
            WRITE: if (s_axi_wvalid && wready_reg) write_next = RESP;
            RESP: if (s_axi_bready && bvalid_reg) write_next = IDLE;
            default: write_next = IDLE;
        endcase
    end
    
    // AXI Read Channel FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            read_state <= IDLE;
            arready_reg <= 1'b0;
            rvalid_reg <= 1'b0;
            rdata_reg <= 32'h0;
        end else begin
            read_state <= read_next;
            
            // Handle read address ready
            if (read_state == IDLE && s_axi_arvalid) begin
                arready_reg <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end
            
            // Handle read data
            if (read_state == READ) begin
                rvalid_reg <= 1'b1;
                
                // Read from appropriate register
                case (s_axi_araddr[5:2])
                    ADDR_HIGH: rdata_reg <= {24'h0, high_reg};
                    ADDR_LOW: rdata_reg <= {24'h0, low_reg};
                    ADDR_RES: rdata_reg <= {24'h0, res_reg};
                    default: rdata_reg <= 32'h0;
                endcase
            end else if (s_axi_rready && rvalid_reg) begin
                rvalid_reg <= 1'b0;
            end
        end
    end
    
    // AXI Read Channel Next State Logic
    always @(*) begin
        read_next = read_state;
        
        case (read_state)
            IDLE: if (s_axi_arvalid) read_next = READ;
            READ: if (s_axi_rready && rvalid_reg) read_next = IDLE;
            default: read_next = IDLE;
        endcase
    end
    
    // AXI output assignments
    assign s_axi_awready = awready_reg;
    assign s_axi_wready = wready_reg;
    assign s_axi_bresp = 2'b00; // OKAY response
    assign s_axi_bvalid = bvalid_reg;
    
    assign s_axi_arready = arready_reg;
    assign s_axi_rdata = rdata_reg;
    assign s_axi_rresp = 2'b00; // OKAY response
    assign s_axi_rvalid = rvalid_reg;
    
endmodule

// Submodule for XNOR operation on 4-bit segments
module XNOR_Segment #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    // Perform XNOR operation - changed from always block to continuous assignment for better timing
    assign result = ~(a ^ b);
endmodule