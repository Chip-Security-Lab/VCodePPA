//SystemVerilog
module sync_signal_recovery (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal registers
    reg [7:0] clean_signal_stage1, clean_signal_stage2;
    reg valid_out_stage1, valid_out_stage2;
    reg [7:0] noisy_signal_reg_stage1, noisy_signal_reg_stage2;
    reg valid_in_reg_stage1, valid_in_reg_stage2;
    
    // Address map offsets
    localparam ADDR_NOISY_SIGNAL = 4'h0;
    localparam ADDR_VALID_IN     = 4'h4;
    localparam ADDR_CLEAN_SIGNAL = 4'h8;
    localparam ADDR_VALID_OUT    = 4'hC;
    
    // AXI4-Lite states
    localparam WRITE_IDLE   = 2'b00;
    localparam WRITE_ADDR   = 2'b01;
    localparam WRITE_DATA   = 2'b10;
    localparam WRITE_RESP   = 2'b11;
    localparam READ_IDLE    = 2'b00;
    localparam READ_ADDR    = 2'b01;
    localparam READ_DATA    = 2'b10;
    
    // State registers
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    reg [3:0] write_addr_reg;
    reg [3:0] read_addr_reg;
    
    // Pre-computed signals for write state machine
    wire write_addr_valid = s_axil_awvalid;
    wire write_data_valid = s_axil_wvalid;
    wire write_resp_ready = s_axil_bready;
    
    // Pre-computed signals for read state machine
    wire read_addr_valid = s_axil_arvalid;
    wire read_data_ready = s_axil_rready;
    
    // Pre-computed signals for data processing
    wire valid_in_active = valid_in_reg_stage1;
    wire [7:0] clean_signal_next = noisy_signal_reg_stage1;
    
    // AXI4-Lite write channel state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_addr_reg <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (write_addr_valid) begin
                        write_state <= WRITE_ADDR;
                        write_addr_reg <= s_axil_awaddr[3:0];
                        s_axil_awready <= 1'b1;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axil_awready <= 1'b0;
                    if (write_data_valid) begin
                        write_state <= WRITE_DATA;
                        s_axil_wready <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    s_axil_wready <= 1'b0;
                    if (s_axil_wstrb[0]) begin
                        case (write_addr_reg)
                            ADDR_NOISY_SIGNAL: noisy_signal_reg_stage1 <= s_axil_wdata[7:0];
                            ADDR_VALID_IN: valid_in_reg_stage1 <= s_axil_wdata[0];
                            default: begin end
                        endcase
                    end
                    write_state <= WRITE_RESP;
                    s_axil_bvalid <= 1'b1;
                    s_axil_bresp <= 2'b00;
                end
                
                WRITE_RESP: begin
                    if (write_resp_ready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite read channel state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
            read_addr_reg <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (read_addr_valid) begin
                        read_state <= READ_ADDR;
                        read_addr_reg <= s_axil_araddr[3:0];
                        s_axil_arready <= 1'b1;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_arready <= 1'b0;
                    read_state <= READ_DATA;
                    s_axil_rvalid <= 1'b1;
                    
                    case (read_addr_reg)
                        ADDR_NOISY_SIGNAL: s_axil_rdata <= {24'h0, noisy_signal_reg_stage2};
                        ADDR_VALID_IN:     s_axil_rdata <= {31'h0, valid_in_reg_stage2};
                        ADDR_CLEAN_SIGNAL: s_axil_rdata <= {24'h0, clean_signal_stage2};
                        ADDR_VALID_OUT:    s_axil_rdata <= {31'h0, valid_out_stage2};
                        default:           s_axil_rdata <= 32'h0;
                    endcase
                    
                    s_axil_rresp <= 2'b00;
                end
                
                READ_DATA: begin
                    if (read_data_ready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Stage 1: Input processing with retimed registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal_stage1 <= 8'b0;
            valid_out_stage1 <= 1'b0;
            noisy_signal_reg_stage2 <= 8'b0;
            valid_in_reg_stage2 <= 1'b0;
        end else begin
            noisy_signal_reg_stage2 <= noisy_signal_reg_stage1;
            valid_in_reg_stage2 <= valid_in_reg_stage1;
            
            if (valid_in_active) begin
                clean_signal_stage1 <= clean_signal_next;
                valid_out_stage1 <= 1'b1;
            end else begin
                valid_out_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Output processing with retimed registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal_stage2 <= 8'b0;
            valid_out_stage2 <= 1'b0;
        end else begin
            clean_signal_stage2 <= clean_signal_stage1;
            valid_out_stage2 <= valid_out_stage1;
        end
    end

endmodule