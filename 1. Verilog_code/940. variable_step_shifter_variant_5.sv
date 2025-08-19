//SystemVerilog
// IEEE 1364-2005 Verilog
module variable_step_shifter #(
    parameter DATA_WIDTH = 16
) (
    // Global signals
    input  wire                      s_axi_aclk,
    input  wire                      s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0]               s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0]               s_axi_wdata,
    input  wire [3:0]                s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0]               s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg  [31:0]               s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);

    // Internal registers
    reg [DATA_WIDTH-1:0] din_reg;
    reg [1:0]            step_mode_reg;
    
    // Register addresses
    localparam ADDR_DIN       = 4'h0;
    localparam ADDR_STEP_MODE = 4'h4;
    localparam ADDR_DOUT      = 4'h8;
    
    // AXI4-Lite state machine registers
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // AXI4-Lite state machine parameters
    localparam IDLE  = 2'b00;
    localparam ADDR  = 2'b01;
    localparam DATA  = 2'b10;
    localparam RESP  = 2'b11;
    
    // Pipeline stage registers
    // Pipeline stage 1: Calculate shift amount
    reg [3:0] shift_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    
    // Pipeline stage 2: Calculate left shift component
    reg [3:0] shift_stage2;
    reg [DATA_WIDTH-1:0] din_stage2;
    reg [DATA_WIDTH-1:0] left_shift_stage2;
    
    // Pipeline stage 3: Calculate right shift component
    reg [3:0] shift_stage3;
    reg [DATA_WIDTH-1:0] din_stage3;
    reg [DATA_WIDTH-1:0] left_shift_stage3;
    reg [DATA_WIDTH-1:0] right_shift_stage3;
    
    // Pipeline stage 4: Final output
    reg [DATA_WIDTH-1:0] dout_stage4;
    
    // Pipeline stage 1: Calculate shift amount
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            shift_stage1 <= 4'b0;
            din_stage1 <= {DATA_WIDTH{1'b0}};
        end else begin
            shift_stage1 <= 1 << step_mode_reg;
            din_stage1 <= din_reg;
        end
    end
    
    // Pipeline stage 2: Calculate left shift component
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            shift_stage2 <= 4'b0;
            din_stage2 <= {DATA_WIDTH{1'b0}};
            left_shift_stage2 <= {DATA_WIDTH{1'b0}};
        end else begin
            shift_stage2 <= shift_stage1;
            din_stage2 <= din_stage1;
            left_shift_stage2 <= din_stage1 << shift_stage1;
        end
    end
    
    // Pipeline stage 3: Calculate right shift component
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            shift_stage3 <= 4'b0;
            din_stage3 <= {DATA_WIDTH{1'b0}};
            left_shift_stage3 <= {DATA_WIDTH{1'b0}};
            right_shift_stage3 <= {DATA_WIDTH{1'b0}};
        end else begin
            shift_stage3 <= shift_stage2;
            din_stage3 <= din_stage2;
            left_shift_stage3 <= left_shift_stage2;
            right_shift_stage3 <= din_stage2 >> (DATA_WIDTH - shift_stage2);
        end
    end
    
    // Pipeline stage 4: Final output
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            dout_stage4 <= {DATA_WIDTH{1'b0}};
        end else begin
            dout_stage4 <= left_shift_stage3 | right_shift_stage3;
        end
    end
    
    // AXI4-Lite Write State Machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state    <= IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            din_reg        <= {DATA_WIDTH{1'b0}};
            step_mode_reg  <= 2'b00;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        
                        // Decode address and write data
                        case (s_axi_awaddr[3:0])
                            ADDR_DIN: begin
                                din_reg <= s_axi_wdata[DATA_WIDTH-1:0];
                                s_axi_bresp <= 2'b00; // OKAY
                            end
                            ADDR_STEP_MODE: begin
                                step_mode_reg <= s_axi_wdata[1:0];
                                s_axi_bresp <= 2'b00; // OKAY
                            end
                            default: begin
                                s_axi_bresp <= 2'b10; // SLVERR
                            end
                        endcase
                        
                        s_axi_bvalid <= 1'b1;
                        write_state <= RESP;
                    end
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // AXI4-Lite Read State Machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state    <= IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b0;
                        
                        // Decode address and prepare read data
                        case (s_axi_araddr[3:0])
                            ADDR_DIN: begin
                                s_axi_rdata <= {{(32-DATA_WIDTH){1'b0}}, din_reg};
                                s_axi_rresp <= 2'b00; // OKAY
                            end
                            ADDR_STEP_MODE: begin
                                s_axi_rdata <= {{30{1'b0}}, step_mode_reg};
                                s_axi_rresp <= 2'b00; // OKAY
                            end
                            ADDR_DOUT: begin
                                s_axi_rdata <= {{(32-DATA_WIDTH){1'b0}}, dout_stage4};
                                s_axi_rresp <= 2'b00; // OKAY
                            end
                            default: begin
                                s_axi_rdata <= 32'h0;
                                s_axi_rresp <= 2'b10; // SLVERR
                            end
                        endcase
                        
                        s_axi_rvalid <= 1'b1;
                        read_state <= RESP;
                    end
                end
                
                RESP: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule