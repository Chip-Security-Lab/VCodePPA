//SystemVerilog
module decoder_multi_protocol (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    
    // Write data channel
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    
    // Write response channel
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output wire [1:0]  s_axi_bresp,
    
    // Read address channel
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    
    // Read data channel
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg  [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    
    // Decoder output
    output reg  [3:0]  sel
);

    // AXI4-Lite response codes
    localparam RESP_OKAY = 2'b00;
    
    // Internal registers
    reg [15:0] addr_reg;
    reg        mode_reg;
    reg        write_in_progress;
    reg        read_in_progress;
    
    // Address decoder logic
    reg [3:0] sel_mode0;
    reg [3:0] sel_mode1;
    
    // Write transaction handling
    assign s_axi_awready = ~write_in_progress;
    assign s_axi_wready  = ~write_in_progress;
    assign s_axi_bresp   = RESP_OKAY;
    
    // Read transaction handling
    assign s_axi_arready = ~read_in_progress;
    assign s_axi_rresp   = RESP_OKAY;
    
    // Write transaction state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            write_in_progress <= 1'b0;
            s_axi_bvalid      <= 1'b0;
            addr_reg          <= 16'h0;
            mode_reg          <= 1'b0;
        end else begin
            // Start write transaction
            if (s_axi_awvalid && s_axi_awready) begin
                write_in_progress <= 1'b1;
                addr_reg          <= s_axi_awaddr[15:0];
            end
            
            // Handle write data
            if (s_axi_wvalid && s_axi_wready && write_in_progress) begin
                if (s_axi_awaddr[7:0] == 8'h00) begin
                    mode_reg <= s_axi_wdata[0];
                end
                s_axi_bvalid <= 1'b1;
                write_in_progress <= 1'b0;
            end
            
            // Complete write response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // Read transaction state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            read_in_progress <= 1'b0;
            s_axi_rvalid     <= 1'b0;
            s_axi_rdata      <= 32'h0;
        end else begin
            // Start read transaction
            if (s_axi_arvalid && s_axi_arready) begin
                read_in_progress <= 1'b1;
                
                // Register map
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= {31'h0, mode_reg};
                    8'h04: s_axi_rdata <= {16'h0, addr_reg};
                    8'h08: s_axi_rdata <= {28'h0, sel};
                    default: s_axi_rdata <= 32'h0;
                endcase
                
                s_axi_rvalid <= 1'b1;
            end
            
            // Complete read transaction
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                read_in_progress <= 1'b0;
            end
        end
    end
    
    // Address decoding logic - same as original core functionality
    always @(*) begin
        if (addr_reg[15:12] == 4'ha) begin
            sel_mode0 = addr_reg[3:0];
        end else begin
            sel_mode0 = 4'b0000;
        end
    end
    
    always @(*) begin
        if (addr_reg[7:4] == 4'h5) begin
            sel_mode1 = addr_reg[3:0];
        end else begin
            sel_mode1 = 4'b0000;
        end
    end
    
    // Output selection based on mode
    always @(*) begin
        case(mode_reg)
            1'b0: sel = sel_mode0;
            1'b1: sel = sel_mode1;
            default: sel = 4'b0000;
        endcase
    end
    
endmodule