//SystemVerilog
// SystemVerilog
module SyncNOT(
    // AXI4-Lite Interface
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    // Write Response Channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    // Read Data Channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal registers
    reg [15:0] input_reg_stage1;
    reg [15:0] input_reg_stage2;
    reg [15:0] input_reg_stage3;
    
    reg [15:0] output_reg_stage1;
    reg [15:0] output_reg_stage2;
    reg [15:0] output_reg_stage3;
    
    // AXI4-Lite FSM states
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    // FSM registers
    reg [1:0] write_state_stage1, write_state_stage2;
    reg [1:0] read_state_stage1, read_state_stage2;
    reg [31:0] read_data_stage1, read_data_stage2;
    
    // Register addresses (word-aligned)
    localparam ADDR_INPUT  = 4'h0; // 0x00
    localparam ADDR_OUTPUT = 4'h4; // 0x04
    
    // AXI4-Lite write channel control
    reg awready_reg_stage1, awready_reg_stage2;
    reg wready_reg_stage1, wready_reg_stage2;
    reg bvalid_reg_stage1, bvalid_reg_stage2;
    reg [1:0] bresp_reg_stage1, bresp_reg_stage2;
    
    // Pipeline control registers for write address path
    reg [31:0] awaddr_stage1, awaddr_stage2;
    reg awvalid_stage1, awvalid_stage2;
    
    // Pipeline control registers for write data path
    reg [31:0] wdata_stage1, wdata_stage2;
    reg wvalid_stage1, wvalid_stage2;
    
    assign s_axi_awready = awready_reg_stage2;
    assign s_axi_wready = wready_reg_stage2;
    assign s_axi_bvalid = bvalid_reg_stage2;
    assign s_axi_bresp = bresp_reg_stage2;
    
    // AXI4-Lite read channel control
    reg arready_reg_stage1, arready_reg_stage2;
    reg rvalid_reg_stage1, rvalid_reg_stage2, rvalid_reg_stage3;
    reg [31:0] rdata_reg_stage1, rdata_reg_stage2, rdata_reg_stage3;
    reg [1:0] rresp_reg_stage1, rresp_reg_stage2, rresp_reg_stage3;
    
    // Pipeline control registers for read address path
    reg [31:0] araddr_stage1, araddr_stage2;
    reg arvalid_stage1, arvalid_stage2;
    
    assign s_axi_arready = arready_reg_stage2;
    assign s_axi_rvalid = rvalid_reg_stage3;
    assign s_axi_rdata = rdata_reg_stage3;
    assign s_axi_rresp = rresp_reg_stage3;
    
    // NOT operation pipeline stages
    wire [3:0] not_result_stage1_part1;
    wire [3:0] not_result_stage1_part2;
    wire [3:0] not_result_stage1_part3;
    wire [3:0] not_result_stage1_part4;
    
    reg [3:0] not_result_stage2_part1;
    reg [3:0] not_result_stage2_part2;
    reg [3:0] not_result_stage2_part3;
    reg [3:0] not_result_stage2_part4;
    
    reg [7:0] not_result_stage3_part1;
    reg [7:0] not_result_stage3_part2;
    
    reg [15:0] not_result_final;
    
    // First stage of NOT operation - split into 4 parts for better timing
    assign not_result_stage1_part1 = ~input_reg_stage1[3:0];
    assign not_result_stage1_part2 = ~input_reg_stage1[7:4];
    assign not_result_stage1_part3 = ~input_reg_stage1[11:8];
    assign not_result_stage1_part4 = ~input_reg_stage1[15:12];
    
    // Pipeline stage registers for address and control signals
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            awaddr_stage1 <= 32'h0;
            awaddr_stage2 <= 32'h0;
            awvalid_stage1 <= 1'b0;
            awvalid_stage2 <= 1'b0;
            
            wdata_stage1 <= 32'h0;
            wdata_stage2 <= 32'h0;
            wvalid_stage1 <= 1'b0;
            wvalid_stage2 <= 1'b0;
            
            araddr_stage1 <= 32'h0;
            araddr_stage2 <= 32'h0;
            arvalid_stage1 <= 1'b0;
            arvalid_stage2 <= 1'b0;
        end else begin
            // Register AW channel signals
            awaddr_stage1 <= s_axi_awaddr;
            awaddr_stage2 <= awaddr_stage1;
            awvalid_stage1 <= s_axi_awvalid;
            awvalid_stage2 <= awvalid_stage1;
            
            // Register W channel signals
            wdata_stage1 <= s_axi_wdata;
            wdata_stage2 <= wdata_stage1;
            wvalid_stage1 <= s_axi_wvalid;
            wvalid_stage2 <= wvalid_stage1;
            
            // Register AR channel signals
            araddr_stage1 <= s_axi_araddr;
            araddr_stage2 <= araddr_stage1;
            arvalid_stage1 <= s_axi_arvalid;
            arvalid_stage2 <= arvalid_stage1;
        end
    end
    
    // NOT operation pipeline stages
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            not_result_stage2_part1 <= 4'h0;
            not_result_stage2_part2 <= 4'h0;
            not_result_stage2_part3 <= 4'h0;
            not_result_stage2_part4 <= 4'h0;
            
            not_result_stage3_part1 <= 8'h0;
            not_result_stage3_part2 <= 8'h0;
            
            not_result_final <= 16'h0;
        end else begin
            // First stage to second stage
            not_result_stage2_part1 <= not_result_stage1_part1;
            not_result_stage2_part2 <= not_result_stage1_part2;
            not_result_stage2_part3 <= not_result_stage1_part3;
            not_result_stage2_part4 <= not_result_stage1_part4;
            
            // Second stage to third stage
            not_result_stage3_part1 <= {not_result_stage2_part2, not_result_stage2_part1};
            not_result_stage3_part2 <= {not_result_stage2_part4, not_result_stage2_part3};
            
            // Third stage to final result
            not_result_final <= {not_result_stage3_part2, not_result_stage3_part1};
        end
    end
    
    // Write state machine with deeper pipeline
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state_stage1 <= IDLE;
            write_state_stage2 <= IDLE;
            awready_reg_stage1 <= 1'b0;
            awready_reg_stage2 <= 1'b0;
            wready_reg_stage1 <= 1'b0;
            wready_reg_stage2 <= 1'b0;
            bvalid_reg_stage1 <= 1'b0;
            bvalid_reg_stage2 <= 1'b0;
            bresp_reg_stage1 <= 2'b00;
            bresp_reg_stage2 <= 2'b00;
            input_reg_stage1 <= 16'h0000;
            input_reg_stage2 <= 16'h0000;
            input_reg_stage3 <= 16'h0000;
        end else begin
            // Pipeline registers update
            write_state_stage2 <= write_state_stage1;
            awready_reg_stage2 <= awready_reg_stage1;
            wready_reg_stage2 <= wready_reg_stage1;
            bvalid_reg_stage2 <= bvalid_reg_stage1;
            bresp_reg_stage2 <= bresp_reg_stage1;
            input_reg_stage2 <= input_reg_stage1;
            input_reg_stage3 <= input_reg_stage2;
            
            // FSM logic for stage 1
            case (write_state_stage1)
                IDLE: begin
                    awready_reg_stage1 <= 1'b1;
                    wready_reg_stage1 <= 1'b1;
                    if (awvalid_stage2 && wvalid_stage2) begin
                        // Both address and data are valid - can process
                        awready_reg_stage1 <= 1'b0;
                        wready_reg_stage1 <= 1'b0;
                        
                        // Process write
                        if (awaddr_stage2[7:0] == ADDR_INPUT) begin
                            input_reg_stage1 <= wdata_stage2[15:0];
                            bresp_reg_stage1 <= 2'b00; // OKAY
                        end else begin
                            bresp_reg_stage1 <= 2'b10; // SLVERR for invalid address
                        end
                        
                        bvalid_reg_stage1 <= 1'b1;
                        write_state_stage1 <= RESP;
                    end else if (awvalid_stage2) begin
                        // Address valid but data not yet - move to ADDR state
                        awready_reg_stage1 <= 1'b0;
                        write_state_stage1 <= ADDR;
                    end
                end
                
                ADDR: begin
                    // Waiting for data
                    if (wvalid_stage2) begin
                        wready_reg_stage1 <= 1'b0;
                        
                        // Process write
                        if (awaddr_stage2[7:0] == ADDR_INPUT) begin
                            input_reg_stage1 <= wdata_stage2[15:0];
                            bresp_reg_stage1 <= 2'b00; // OKAY
                        end else begin
                            bresp_reg_stage1 <= 2'b10; // SLVERR for invalid address
                        end
                        
                        bvalid_reg_stage1 <= 1'b1;
                        write_state_stage1 <= RESP;
                    end
                end
                
                RESP: begin
                    // Waiting for response acknowledgment
                    if (s_axi_bready) begin
                        bvalid_reg_stage1 <= 1'b0;
                        awready_reg_stage1 <= 1'b1;
                        wready_reg_stage1 <= 1'b1;
                        write_state_stage1 <= IDLE;
                    end
                end
                
                default: begin
                    write_state_stage1 <= IDLE;
                end
            endcase
        end
    end
    
    // Read state machine with deeper pipeline
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state_stage1 <= IDLE;
            read_state_stage2 <= IDLE;
            arready_reg_stage1 <= 1'b0;
            arready_reg_stage2 <= 1'b0;
            rvalid_reg_stage1 <= 1'b0;
            rvalid_reg_stage2 <= 1'b0;
            rvalid_reg_stage3 <= 1'b0;
            rdata_reg_stage1 <= 32'h0;
            rdata_reg_stage2 <= 32'h0;
            rdata_reg_stage3 <= 32'h0;
            rresp_reg_stage1 <= 2'b00;
            rresp_reg_stage2 <= 2'b00;
            rresp_reg_stage3 <= 2'b00;
        end else begin
            // Pipeline registers update
            read_state_stage2 <= read_state_stage1;
            arready_reg_stage2 <= arready_reg_stage1;
            rvalid_reg_stage2 <= rvalid_reg_stage1;
            rvalid_reg_stage3 <= rvalid_reg_stage2;
            rdata_reg_stage2 <= rdata_reg_stage1;
            rdata_reg_stage3 <= rdata_reg_stage2;
            rresp_reg_stage2 <= rresp_reg_stage1;
            rresp_reg_stage3 <= rresp_reg_stage2;
            
            // FSM logic for stage 1
            case (read_state_stage1)
                IDLE: begin
                    arready_reg_stage1 <= 1'b1;
                    if (arvalid_stage2) begin
                        arready_reg_stage1 <= 1'b0;
                        
                        // Prepare data based on address
                        if (araddr_stage2[7:0] == ADDR_INPUT) begin
                            rdata_reg_stage1 <= {16'h0000, input_reg_stage3};
                            rresp_reg_stage1 <= 2'b00; // OKAY
                        end else if (araddr_stage2[7:0] == ADDR_OUTPUT) begin
                            rdata_reg_stage1 <= {16'h0000, output_reg_stage3};
                            rresp_reg_stage1 <= 2'b00; // OKAY
                        end else begin
                            rdata_reg_stage1 <= 32'h0;
                            rresp_reg_stage1 <= 2'b10; // SLVERR for invalid address
                        end
                        
                        rvalid_reg_stage1 <= 1'b1;
                        read_state_stage1 <= RESP;
                    end
                end
                
                RESP: begin
                    // Waiting for read data acknowledgment
                    if (s_axi_rready) begin
                        rvalid_reg_stage1 <= 1'b0;
                        arready_reg_stage1 <= 1'b1;
                        read_state_stage1 <= IDLE;
                    end
                end
                
                default: begin
                    read_state_stage1 <= IDLE;
                end
            endcase
        end
    end
    
    // Core functionality - register the NOT result through pipeline stages
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            output_reg_stage1 <= 16'h0000;
            output_reg_stage2 <= 16'h0000;
            output_reg_stage3 <= 16'h0000;
        end else begin
            output_reg_stage1 <= not_result_final;
            output_reg_stage2 <= output_reg_stage1;
            output_reg_stage3 <= output_reg_stage2;
        end
    end
    
endmodule