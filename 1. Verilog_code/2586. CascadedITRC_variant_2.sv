//SystemVerilog
module CascadedITRC (
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
    
    // Interrupt Outputs
    output reg master_irq,
    output reg [2:0] irq_vector
);

    // Internal registers for AXI4-Lite
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    reg [31:0] irq_mask_reg;
    reg [31:0] irq_status_reg;
    
    // Stage 1 signals
    wire [1:0] low_level_active_stage1;
    reg [2:0] low_priority0_stage1;
    reg [2:0] low_priority1_stage1;
    reg [1:0] top_level_irq_stage1;
    reg [3:0] low_level_irq0_stage1;
    reg [3:0] low_level_irq1_stage1;

    // Stage 2 signals
    reg [1:0] low_level_active_stage2;
    reg [2:0] low_priority0_stage2;
    reg [2:0] low_priority1_stage2;
    reg [1:0] top_level_irq_stage2;

    // AXI4-Lite Write FSM
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;

    // AXI4-Lite Read FSM
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;

    // Stage 1: Priority calculation
    assign low_level_active_stage1[0] = |(low_level_irq0_stage1 & irq_mask_reg[3:0]);
    assign low_level_active_stage1[1] = |(low_level_irq1_stage1 & irq_mask_reg[7:4]);

    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            control_reg <= 32'h0;
            irq_mask_reg <= 32'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (AWVALID) begin
                        AWREADY <= 1'b1;
                        write_state <= WRITE_ADDR;
                    end
                end
                WRITE_ADDR: begin
                    AWREADY <= 1'b0;
                    if (WVALID) begin
                        WREADY <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                WRITE_DATA: begin
                    WREADY <= 1'b0;
                    case (AWADDR[7:0])
                        8'h00: control_reg <= WDATA;
                        8'h04: irq_mask_reg <= WDATA;
                        default: BRESP <= 2'b10; // SLVERR
                    endcase
                    write_state <= WRITE_RESP;
                end
                WRITE_RESP: begin
                    BVALID <= 1'b1;
                    if (BREADY) begin
                        BVALID <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
            endcase
        end
    end

    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
            RDATA <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (ARVALID) begin
                        ARREADY <= 1'b1;
                        read_state <= READ_ADDR;
                    end
                end
                READ_ADDR: begin
                    ARREADY <= 1'b0;
                    case (ARADDR[7:0])
                        8'h00: RDATA <= control_reg;
                        8'h04: RDATA <= irq_mask_reg;
                        8'h08: RDATA <= status_reg;
                        8'h0C: RDATA <= irq_status_reg;
                        default: RRESP <= 2'b10; // SLVERR
                    endcase
                    RVALID <= 1'b1;
                    read_state <= READ_DATA;
                end
                READ_DATA: begin
                    if (RREADY) begin
                        RVALID <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
            endcase
        end
    end

    // Main processing logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            // Stage 1 registers
            low_priority0_stage1 <= 0;
            low_priority1_stage1 <= 0;
            top_level_irq_stage1 <= 0;
            low_level_irq0_stage1 <= 0;
            low_level_irq1_stage1 <= 0;
            
            // Stage 2 registers
            low_level_active_stage2 <= 0;
            low_priority0_stage2 <= 0;
            low_priority1_stage2 <= 0;
            top_level_irq_stage2 <= 0;
            
            // Output registers
            master_irq <= 0;
            irq_vector <= 0;
            
            // Status registers
            status_reg <= 0;
            irq_status_reg <= 0;
        end else begin
            // Stage 1: Priority calculation
            if (low_level_irq0_stage1[3]) low_priority0_stage1 <= 3;
            else if (low_level_irq0_stage1[2]) low_priority0_stage1 <= 2;
            else if (low_level_irq0_stage1[1]) low_priority0_stage1 <= 1;
            else if (low_level_irq0_stage1[0]) low_priority0_stage1 <= 0;
            
            if (low_level_irq1_stage1[3]) low_priority1_stage1 <= 3;
            else if (low_level_irq1_stage1[2]) low_priority1_stage1 <= 2;
            else if (low_level_irq1_stage1[1]) low_priority1_stage1 <= 1;
            else if (low_level_irq1_stage1[0]) low_priority1_stage1 <= 0;
            
            // Stage 1: Input sampling
            top_level_irq_stage1 <= control_reg[1:0];
            low_level_irq0_stage1 <= control_reg[7:4];
            low_level_irq1_stage1 <= control_reg[11:8];
            
            // Stage 2: Intermediate results
            low_level_active_stage2 <= low_level_active_stage1;
            low_priority0_stage2 <= low_priority0_stage1;
            low_priority1_stage2 <= low_priority1_stage1;
            top_level_irq_stage2 <= top_level_irq_stage1;
            
            // Stage 2: Final output calculation
            master_irq <= |(top_level_irq_stage2 & low_level_active_stage2);
            if (top_level_irq_stage2[1] && low_level_active_stage2[1])
                irq_vector <= {1'b1, low_priority1_stage2};
            else if (top_level_irq_stage2[0] && low_level_active_stage2[0])
                irq_vector <= {1'b0, low_priority0_stage2};
                
            // Update status registers
            status_reg <= {29'h0, master_irq, irq_vector};
            irq_status_reg <= {16'h0, low_level_irq1_stage1, low_level_irq0_stage1};
        end
    end
endmodule