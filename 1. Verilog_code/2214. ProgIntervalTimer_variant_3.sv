//SystemVerilog
module ProgIntervalTimer (
    // Global Signals
    input wire clk,
    input wire rst_n,
    
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
    
    // Interrupt output
    output wire intr
);

    // Internal registers
    reg [15:0] threshold_reg;
    reg [15:0] cnt_stage1, cnt_stage2, cnt_final;
    reg intr_reg_stage1, intr_reg_stage2, intr_reg_final;
    
    // Memory map addresses (byte addressed)
    localparam ADDR_THRESHOLD = 4'h0;
    localparam ADDR_CONTROL   = 4'h4;
    localparam ADDR_STATUS    = 4'h8;
    
    // Control register bits
    localparam CTRL_LOAD_BIT  = 0;
    
    // Status register bits
    localparam STAT_INTR_BIT  = 0;
    
    // AXI response codes
    localparam RESP_OKAY      = 2'b00;
    localparam RESP_SLVERR    = 2'b10;
    
    // Write transaction pipeline stages
    reg [1:0] write_state_stage1;
    reg [1:0] write_state_stage2;
    reg [1:0] write_state_stage3;
    
    localparam WRITE_IDLE     = 2'b00;
    localparam WRITE_DATA     = 2'b01;
    localparam WRITE_RESP     = 2'b10;
    
    // Read transaction pipeline stages
    reg [1:0] read_state_stage1;
    reg [1:0] read_state_stage2;
    reg [1:0] read_state_stage3;
    
    localparam READ_IDLE      = 2'b00;
    localparam READ_DATA      = 2'b01;
    
    // Signals for control with pipeline stages
    reg load_sig_stage1, load_sig_stage2, load_sig_final;
    reg [31:0] read_data_stage1, read_data_stage2, read_data_final;
    
    // Pipeline registers for AXI write interface
    reg s_axil_awready_stage1, s_axil_awready_stage2;
    reg s_axil_wready_stage1, s_axil_wready_stage2;
    reg s_axil_bvalid_stage1, s_axil_bvalid_stage2;
    reg [1:0] s_axil_bresp_stage1, s_axil_bresp_stage2;
    
    // Pipeline registers for AXI read interface
    reg s_axil_arready_stage1, s_axil_arready_stage2;
    reg s_axil_rvalid_stage1, s_axil_rvalid_stage2;
    reg [1:0] s_axil_rresp_stage1, s_axil_rresp_stage2;
    reg [31:0] s_axil_rdata_stage1, s_axil_rdata_stage2;
    
    // Capture address registers
    reg [31:0] s_axil_awaddr_captured;
    reg [31:0] s_axil_araddr_captured;
    
    // Capture data registers
    reg [31:0] s_axil_wdata_captured;
    reg [3:0] s_axil_wstrb_captured;
    
    // Timer logic with deeper pipeline (core functionality)
    always @(posedge clk) begin
        if (!rst_n) begin
            // Stage 1 reset
            cnt_stage1 <= 16'h0;
            intr_reg_stage1 <= 1'b0;
            
            // Stage 2 reset
            cnt_stage2 <= 16'h0;
            intr_reg_stage2 <= 1'b0;
            
            // Final stage reset
            cnt_final <= 16'h0;
            intr_reg_final <= 1'b0;
        end
        else begin
            // Stage 1: Initial calculation and check
            if (load_sig_final) begin
                cnt_stage1 <= threshold_reg;
                intr_reg_stage1 <= 1'b0;
            end
            else begin
                cnt_stage1 <= (cnt_final == 16'h0) ? 16'h0 : cnt_final - 16'h1;
                intr_reg_stage1 <= (cnt_final == 16'h1);
            end
            
            // Stage 2: Forward to next stage
            cnt_stage2 <= cnt_stage1;
            intr_reg_stage2 <= intr_reg_stage1;
            
            // Final stage: Output values
            cnt_final <= cnt_stage2;
            intr_reg_final <= intr_reg_stage2;
        end
    end
    
    // Write transaction FSM with deeper pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            // Stage 1 reset
            write_state_stage1 <= WRITE_IDLE;
            s_axil_awready_stage1 <= 1'b0;
            s_axil_wready_stage1 <= 1'b0;
            s_axil_bvalid_stage1 <= 1'b0;
            s_axil_bresp_stage1 <= RESP_OKAY;
            load_sig_stage1 <= 1'b0;
            
            // Stage 2 reset
            write_state_stage2 <= WRITE_IDLE;
            s_axil_awready_stage2 <= 1'b0;
            s_axil_wready_stage2 <= 1'b0;
            s_axil_bvalid_stage2 <= 1'b0;
            s_axil_bresp_stage2 <= RESP_OKAY;
            load_sig_stage2 <= 1'b0;
            
            // Final stage reset
            write_state_stage3 <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            threshold_reg <= 16'h0;
            load_sig_final <= 1'b0;
            
            // Reset captured values
            s_axil_awaddr_captured <= 32'h0;
            s_axil_wdata_captured <= 32'h0;
            s_axil_wstrb_captured <= 4'h0;
        end 
        else begin
            // Default values for stage 1
            load_sig_stage1 <= 1'b0;
            
            // Stage 1: Initial FSM processing
            case (write_state_stage1)
                WRITE_IDLE: begin
                    s_axil_awready_stage1 <= 1'b1;
                    s_axil_wready_stage1 <= 1'b1;
                    
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        // Both address and data are valid, process write
                        s_axil_awready_stage1 <= 1'b0;
                        s_axil_wready_stage1 <= 1'b0;
                        
                        // Capture address and data for later stages
                        s_axil_awaddr_captured <= s_axil_awaddr;
                        s_axil_wdata_captured <= s_axil_wdata;
                        s_axil_wstrb_captured <= s_axil_wstrb;
                        
                        // Handle write based on address
                        case (s_axil_awaddr[3:0])
                            ADDR_THRESHOLD: begin
                                s_axil_bresp_stage1 <= RESP_OKAY;
                            end
                            ADDR_CONTROL: begin
                                if (s_axil_wstrb[0] && s_axil_wdata[CTRL_LOAD_BIT]) 
                                    load_sig_stage1 <= 1'b1;
                                s_axil_bresp_stage1 <= RESP_OKAY;
                            end
                            default: begin
                                // Invalid address
                                s_axil_bresp_stage1 <= RESP_SLVERR;
                            end
                        endcase
                        
                        write_state_stage1 <= WRITE_RESP;
                        s_axil_bvalid_stage1 <= 1'b1;
                    end
                    else if (s_axil_awvalid) begin
                        // Only address is valid
                        s_axil_awready_stage1 <= 1'b0;
                        s_axil_awaddr_captured <= s_axil_awaddr;
                        write_state_stage1 <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    s_axil_wready_stage1 <= 1'b1;
                    
                    if (s_axil_wvalid) begin
                        s_axil_wready_stage1 <= 1'b0;
                        s_axil_wdata_captured <= s_axil_wdata;
                        s_axil_wstrb_captured <= s_axil_wstrb;
                        
                        // Handle write based on captured address
                        case (s_axil_awaddr_captured[3:0])
                            ADDR_THRESHOLD: begin
                                s_axil_bresp_stage1 <= RESP_OKAY;
                            end
                            ADDR_CONTROL: begin
                                if (s_axil_wstrb[0] && s_axil_wdata[CTRL_LOAD_BIT]) 
                                    load_sig_stage1 <= 1'b1;
                                s_axil_bresp_stage1 <= RESP_OKAY;
                            end
                            default: begin
                                // Invalid address
                                s_axil_bresp_stage1 <= RESP_SLVERR;
                            end
                        endcase
                        
                        write_state_stage1 <= WRITE_RESP;
                        s_axil_bvalid_stage1 <= 1'b1;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready) begin
                        s_axil_bvalid_stage1 <= 1'b0;
                        write_state_stage1 <= WRITE_IDLE;
                        s_axil_awready_stage1 <= 1'b1;
                        s_axil_wready_stage1 <= 1'b1;
                    end
                end
                
                default: begin
                    write_state_stage1 <= WRITE_IDLE;
                end
            endcase

            // Stage 2: Middle Pipeline Processing
            write_state_stage2 <= write_state_stage1;
            s_axil_awready_stage2 <= s_axil_awready_stage1;
            s_axil_wready_stage2 <= s_axil_wready_stage1;
            s_axil_bvalid_stage2 <= s_axil_bvalid_stage1;
            s_axil_bresp_stage2 <= s_axil_bresp_stage1;
            load_sig_stage2 <= load_sig_stage1;
            
            // Final Stage: Output values and register updates
            write_state_stage3 <= write_state_stage2;
            s_axil_awready <= s_axil_awready_stage2;
            s_axil_wready <= s_axil_wready_stage2;
            s_axil_bvalid <= s_axil_bvalid_stage2;
            s_axil_bresp <= s_axil_bresp_stage2;
            load_sig_final <= load_sig_stage2;
            
            // Update threshold register in final stage
            if (write_state_stage2 == WRITE_RESP && 
                s_axil_awaddr_captured[3:0] == ADDR_THRESHOLD) begin
                if (s_axil_wstrb_captured[0]) threshold_reg[7:0] <= s_axil_wdata_captured[7:0];
                if (s_axil_wstrb_captured[1]) threshold_reg[15:8] <= s_axil_wdata_captured[15:8];
            end
        end
    end
    
    // Read transaction FSM with deeper pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            // Stage 1 reset
            read_state_stage1 <= READ_IDLE;
            s_axil_arready_stage1 <= 1'b0;
            s_axil_rvalid_stage1 <= 1'b0;
            s_axil_rresp_stage1 <= RESP_OKAY;
            read_data_stage1 <= 32'h0;
            
            // Stage 2 reset
            read_state_stage2 <= READ_IDLE;
            s_axil_arready_stage2 <= 1'b0;
            s_axil_rvalid_stage2 <= 1'b0;
            s_axil_rresp_stage2 <= RESP_OKAY;
            s_axil_rdata_stage1 <= 32'h0;
            read_data_stage2 <= 32'h0;
            
            // Final stage reset
            read_state_stage3 <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h0;
            read_data_final <= 32'h0;
            
            // Reset captured address
            s_axil_araddr_captured <= 32'h0;
        end 
        else begin
            // Stage 1: Initial FSM processing
            case (read_state_stage1)
                READ_IDLE: begin
                    s_axil_arready_stage1 <= 1'b1;
                    
                    if (s_axil_arvalid) begin
                        s_axil_arready_stage1 <= 1'b0;
                        read_state_stage1 <= READ_DATA;
                        s_axil_araddr_captured <= s_axil_araddr;
                        
                        // Prepare read data based on address
                        case (s_axil_araddr[3:0])
                            ADDR_THRESHOLD: begin
                                read_data_stage1 <= {16'h0, threshold_reg};
                                s_axil_rresp_stage1 <= RESP_OKAY;
                            end
                            ADDR_STATUS: begin
                                read_data_stage1 <= {31'h0, intr_reg_final};
                                s_axil_rresp_stage1 <= RESP_OKAY;
                            end
                            ADDR_CONTROL: begin
                                read_data_stage1 <= 32'h0; // Control register is write-only
                                s_axil_rresp_stage1 <= RESP_OKAY;
                            end
                            default: begin
                                // Invalid address
                                read_data_stage1 <= 32'h0;
                                s_axil_rresp_stage1 <= RESP_SLVERR;
                            end
                        endcase
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid_stage1 <= 1'b1;
                    
                    if (s_axil_rready) begin
                        s_axil_rvalid_stage1 <= 1'b0;
                        read_state_stage1 <= READ_IDLE;
                        s_axil_arready_stage1 <= 1'b1;
                    end
                end
                
                default: begin
                    read_state_stage1 <= READ_IDLE;
                end
            endcase

            // Stage 2: Middle pipeline processing
            read_state_stage2 <= read_state_stage1;
            s_axil_arready_stage2 <= s_axil_arready_stage1;
            s_axil_rvalid_stage2 <= s_axil_rvalid_stage1;
            s_axil_rresp_stage2 <= s_axil_rresp_stage1;
            read_data_stage2 <= read_data_stage1;
            s_axil_rdata_stage1 <= read_data_stage1;
            
            // Final stage: Output values
            read_state_stage3 <= read_state_stage2;
            s_axil_arready <= s_axil_arready_stage2;
            s_axil_rvalid <= s_axil_rvalid_stage2;
            s_axil_rresp <= s_axil_rresp_stage2;
            read_data_final <= read_data_stage2;
            s_axil_rdata <= s_axil_rdata_stage1;
        end
    end
    
    // Connect interrupt output to final pipeline stage
    assign intr = intr_reg_final;

endmodule