//SystemVerilog
module sparse_crossbar (
    input wire clock,
    input wire reset,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original outputs (now connected internally)
    output wire [7:0] out_X, out_Y, out_Z
);

    // Internal registers for crossbar functionality
    reg [7:0] in_A_reg, in_B_reg, in_C_reg, in_D_reg;
    reg [1:0] sel_X_reg, sel_Y_reg, sel_Z_reg;
    
    // Output registers
    reg [7:0] out_X_reg, out_Y_reg, out_Z_reg;
    
    // Input registers for AXI signals
    reg [31:0] s_axil_awaddr_reg;
    reg s_axil_awvalid_reg;
    reg [31:0] s_axil_wdata_reg;
    reg [3:0] s_axil_wstrb_reg;
    reg s_axil_wvalid_reg;
    reg s_axil_bready_reg;
    reg [31:0] s_axil_araddr_reg;
    reg s_axil_arvalid_reg;
    reg s_axil_rready_reg;
    
    // AXI4-Lite state machine registers
    reg [2:0] write_state;
    reg [1:0] read_state;
    reg [31:0] read_address;
    reg [31:0] write_address;
    
    // State machine parameters
    localparam WRITE_IDLE = 3'b000;
    localparam WRITE_ADDR = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam WRITE_RESP = 3'b011;
    localparam WRITE_DONE = 3'b100;
    
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // Address map parameters
    localparam ADDR_IN_A    = 8'h00;
    localparam ADDR_IN_B    = 8'h04;
    localparam ADDR_IN_C    = 8'h08;
    localparam ADDR_IN_D    = 8'h0C;
    localparam ADDR_SEL_X   = 8'h10;
    localparam ADDR_SEL_Y   = 8'h14;
    localparam ADDR_SEL_Z   = 8'h18;
    localparam ADDR_OUT_X   = 8'h20;
    localparam ADDR_OUT_Y   = 8'h24;
    localparam ADDR_OUT_Z   = 8'h28;
    
    // Register AXI input signals
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            s_axil_awaddr_reg <= 32'h0;
            s_axil_awvalid_reg <= 1'b0;
            s_axil_wdata_reg <= 32'h0;
            s_axil_wstrb_reg <= 4'h0;
            s_axil_wvalid_reg <= 1'b0;
            s_axil_bready_reg <= 1'b0;
            s_axil_araddr_reg <= 32'h0;
            s_axil_arvalid_reg <= 1'b0;
            s_axil_rready_reg <= 1'b0;
        end else begin
            s_axil_awaddr_reg <= s_axil_awaddr;
            s_axil_awvalid_reg <= s_axil_awvalid;
            s_axil_wdata_reg <= s_axil_wdata;
            s_axil_wstrb_reg <= s_axil_wstrb;
            s_axil_wvalid_reg <= s_axil_wvalid;
            s_axil_bready_reg <= s_axil_bready;
            s_axil_araddr_reg <= s_axil_araddr;
            s_axil_arvalid_reg <= s_axil_arvalid;
            s_axil_rready_reg <= s_axil_rready;
        end
    end
    
    // Write state machine
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_address <= 32'h0;
            
            // Initialize input registers
            in_A_reg <= 8'h00;
            in_B_reg <= 8'h00;
            in_C_reg <= 8'h00;
            in_D_reg <= 8'h00;
            sel_X_reg <= 2'b00;
            sel_Y_reg <= 2'b00;
            sel_Z_reg <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid_reg && s_axil_awready) begin
                        write_address <= s_axil_awaddr_reg;
                        s_axil_awready <= 1'b0;
                        write_state <= WRITE_DATA;
                        s_axil_wready <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid_reg && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        
                        // Register write operations
                        case (write_address[7:0])
                            ADDR_IN_A: in_A_reg <= s_axil_wdata_reg[7:0];
                            ADDR_IN_B: in_B_reg <= s_axil_wdata_reg[7:0];
                            ADDR_IN_C: in_C_reg <= s_axil_wdata_reg[7:0];
                            ADDR_IN_D: in_D_reg <= s_axil_wdata_reg[7:0];
                            ADDR_SEL_X: sel_X_reg <= s_axil_wdata_reg[1:0];
                            ADDR_SEL_Y: sel_Y_reg <= s_axil_wdata_reg[1:0];
                            ADDR_SEL_Z: sel_Z_reg <= s_axil_wdata_reg[1:0];
                            default: ; // No operation for invalid addresses
                        endcase
                        
                        write_state <= WRITE_RESP;
                        s_axil_bresp <= 2'b00; // OKAY response
                        s_axil_bvalid <= 1'b1;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready_reg && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                        s_axil_awready <= 1'b1;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // Read state machine
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            read_address <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid_reg && s_axil_arready) begin
                        read_address <= s_axil_araddr_reg;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                    
                    // Register read operations
                    case (read_address[7:0])
                        ADDR_IN_A: s_axil_rdata <= {24'h0, in_A_reg};
                        ADDR_IN_B: s_axil_rdata <= {24'h0, in_B_reg};
                        ADDR_IN_C: s_axil_rdata <= {24'h0, in_C_reg};
                        ADDR_IN_D: s_axil_rdata <= {24'h0, in_D_reg};
                        ADDR_SEL_X: s_axil_rdata <= {30'h0, sel_X_reg};
                        ADDR_SEL_Y: s_axil_rdata <= {30'h0, sel_Y_reg};
                        ADDR_SEL_Z: s_axil_rdata <= {30'h0, sel_Z_reg};
                        ADDR_OUT_X: s_axil_rdata <= {24'h0, out_X_reg};
                        ADDR_OUT_Y: s_axil_rdata <= {24'h0, out_Y_reg};
                        ADDR_OUT_Z: s_axil_rdata <= {24'h0, out_Z_reg};
                        default: s_axil_rdata <= 32'h0;
                    endcase
                    
                    if (s_axil_rready_reg && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                        s_axil_arready <= 1'b1;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Intermediates for input selection muxing
    reg [7:0] X_input, Y_input, Z_input;
    
    // First stage: mux select logic (moved from the combinational always block)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            X_input <= 8'h00;
            Y_input <= 8'h00;
            Z_input <= 8'h00;
        end else begin
            // Output X selection logic
            case (sel_X_reg)
                2'b00: X_input <= in_A_reg;
                2'b01: X_input <= in_B_reg;
                2'b10: X_input <= in_D_reg;
                default: X_input <= 8'h00;
            endcase
            
            // Output Y selection logic
            case (sel_Y_reg)
                2'b00: Y_input <= in_A_reg;
                2'b01: Y_input <= in_B_reg;
                2'b10: Y_input <= in_C_reg;
                default: Y_input <= 8'h00;
            endcase
            
            // Output Z selection logic
            case (sel_Z_reg)
                2'b00: Z_input <= in_A_reg;
                2'b01: Z_input <= in_C_reg;
                default: Z_input <= 8'h00;
            endcase
        end
    end
    
    // Second stage: Output registers update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out_X_reg <= 8'h00;
            out_Y_reg <= 8'h00;
            out_Z_reg <= 8'h00;
        end else begin
            out_X_reg <= X_input;
            out_Y_reg <= Y_input;
            out_Z_reg <= Z_input;
        end
    end
    
    // Connect output registers to module outputs
    assign out_X = out_X_reg;
    assign out_Y = out_Y_reg;
    assign out_Z = out_Z_reg;
    
endmodule