//SystemVerilog
module Comparator_AXIWrapper #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    input                              S_AXI_ACLK,
    input                              S_AXI_ARESETN,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input                              S_AXI_AWVALID,
    output                             S_AXI_AWREADY,
    input  [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_WDATA,
    input                              S_AXI_WVALID,
    output                             S_AXI_WREADY,
    output [1:0]                       S_AXI_BRESP,
    output                             S_AXI_BVALID,
    input                              S_AXI_BREADY,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input                              S_AXI_ARVALID,
    output                             S_AXI_ARREADY,
    output [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_RDATA,
    output [1:0]                       S_AXI_RRESP,
    output                             S_AXI_RVALID,
    input                              S_AXI_RREADY,
    output                             irq
);

    // Internal interconnect signals
    wire [C_S_AXI_ADDR_WIDTH-1:0] write_addr;
    wire write_en;
    wire [C_S_AXI_ADDR_WIDTH-1:0] read_addr;
    wire read_en;
    wire [C_S_AXI_DATA_WIDTH-1:0] read_data;
    wire [C_S_AXI_DATA_WIDTH-1:0] comp_a;
    wire [C_S_AXI_DATA_WIDTH-1:0] comp_b;
    wire ctrl;
    wire comp_result;

    // AXI Lite Interface module
    AXI_Lite_Interface #(
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) axi_interface (
        .ACLK(S_AXI_ACLK),
        .ARESETN(S_AXI_ARESETN),
        .AWADDR(S_AXI_AWADDR),
        .AWVALID(S_AXI_AWVALID),
        .AWREADY(S_AXI_AWREADY),
        .WDATA(S_AXI_WDATA),
        .WVALID(S_AXI_WVALID),
        .WREADY(S_AXI_WREADY),
        .BRESP(S_AXI_BRESP),
        .BVALID(S_AXI_BVALID),
        .BREADY(S_AXI_BREADY),
        .ARADDR(S_AXI_ARADDR),
        .ARVALID(S_AXI_ARVALID),
        .ARREADY(S_AXI_ARREADY),
        .RDATA(S_AXI_RDATA),
        .RRESP(S_AXI_RRESP),
        .RVALID(S_AXI_RVALID),
        .RREADY(S_AXI_RREADY),
        .write_addr(write_addr),
        .write_en(write_en),
        .read_addr(read_addr),
        .read_en(read_en),
        .read_data(read_data)
    );

    // Register Bank module
    Register_Bank #(
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) reg_bank (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .write_addr(write_addr),
        .write_en(write_en),
        .write_data(S_AXI_WDATA),
        .read_addr(read_addr),
        .read_en(read_en),
        .read_data(read_data),
        .comp_a(comp_a),
        .comp_b(comp_b),
        .ctrl(ctrl)
    );

    // Comparator logic module
    Comparator_Logic comp_logic (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .comp_a(comp_a),
        .comp_b(comp_b),
        .ctrl(ctrl),
        .irq(irq)
    );

endmodule

module AXI_Lite_Write_Channel #(
    parameter ADDR_WIDTH = 4
)(
    input                      clk,
    input                      rst_n,
    // AXI Write Address Channel
    input  [ADDR_WIDTH-1:0]    AWADDR,
    input                      AWVALID,
    output reg                 AWREADY,
    // AXI Write Data Channel
    input                      WVALID,
    output reg                 WREADY,
    // AXI Write Response Channel
    output reg [1:0]           BRESP,
    output reg                 BVALID,
    input                      BREADY,
    // User Interface
    output reg [ADDR_WIDTH-1:0] write_addr,
    output reg                 write_en
);

    // FSM states
    localparam IDLE = 2'b00;
    localparam ADDR_PHASE = 2'b01;
    localparam DATA_PHASE = 2'b10;
    localparam RESP_PHASE = 2'b11;
    
    reg [1:0] state, next_state;
    
    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (AWVALID)
                    next_state = ADDR_PHASE;
            
            ADDR_PHASE:
                next_state = DATA_PHASE;
                    
            DATA_PHASE:
                if (WVALID)
                    next_state = RESP_PHASE;
                    
            RESP_PHASE:
                if (BREADY)
                    next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            write_addr <= {ADDR_WIDTH{1'b0}};
            write_en <= 1'b0;
        end else begin
            // Default values
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            write_en <= 1'b0;
            
            case (state)
                IDLE: begin
                    // Reset response channel
                    BVALID <= 1'b0;
                end
                
                ADDR_PHASE: begin
                    AWREADY <= 1'b1;
                    write_addr <= AWADDR;
                end
                
                DATA_PHASE: begin
                    WREADY <= 1'b1;
                    if (WVALID)
                        write_en <= 1'b1;
                end
                
                RESP_PHASE: begin
                    BVALID <= 1'b1;
                    BRESP <= 2'b00; // OKAY response
                end
            endcase
        end
    end
endmodule

module AXI_Lite_Read_Channel #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,
    // AXI Read Address Channel
    input  [ADDR_WIDTH-1:0]     ARADDR,
    input                       ARVALID,
    output reg                  ARREADY,
    // AXI Read Data Channel
    output reg [DATA_WIDTH-1:0] RDATA,
    output reg [1:0]            RRESP,
    output reg                  RVALID,
    input                       RREADY,
    // User Interface
    output reg [ADDR_WIDTH-1:0] read_addr,
    output reg                  read_en,
    input      [DATA_WIDTH-1:0] read_data
);

    // FSM states
    localparam IDLE = 2'b00;
    localparam ADDR_PHASE = 2'b01;
    localparam DATA_PHASE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (ARVALID)
                    next_state = ADDR_PHASE;
            
            ADDR_PHASE:
                next_state = DATA_PHASE;
                    
            DATA_PHASE:
                if (RREADY)
                    next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RDATA <= {DATA_WIDTH{1'b0}};
            RRESP <= 2'b00;
            read_addr <= {ADDR_WIDTH{1'b0}};
            read_en <= 1'b0;
        end else begin
            // Default values
            ARREADY <= 1'b0;
            read_en <= 1'b0;
            
            case (state)
                IDLE: begin
                    // Reset data channel
                    RVALID <= 1'b0;
                end
                
                ADDR_PHASE: begin
                    ARREADY <= 1'b1;
                    read_addr <= ARADDR;
                    read_en <= 1'b1;
                end
                
                DATA_PHASE: begin
                    RVALID <= 1'b1;
                    RRESP <= 2'b00; // OKAY response
                    RDATA <= read_data;
                end
            endcase
        end
    end
endmodule

module AXI_Lite_Interface #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input                       ACLK,
    input                       ARESETN,
    // Write Address Channel
    input  [ADDR_WIDTH-1:0]     AWADDR,
    input                       AWVALID,
    output                      AWREADY,
    // Write Data Channel
    input  [DATA_WIDTH-1:0]     WDATA,
    input                       WVALID,
    output                      WREADY,
    // Write Response Channel
    output [1:0]                BRESP,
    output                      BVALID,
    input                       BREADY,
    // Read Address Channel
    input  [ADDR_WIDTH-1:0]     ARADDR,
    input                       ARVALID,
    output                      ARREADY,
    // Read Data Channel
    output [DATA_WIDTH-1:0]     RDATA,
    output [1:0]                RRESP,
    output                      RVALID,
    input                       RREADY,
    // User Interface
    output [ADDR_WIDTH-1:0]     write_addr,
    output                      write_en,
    output [ADDR_WIDTH-1:0]     read_addr,
    output                      read_en,
    input  [DATA_WIDTH-1:0]     read_data
);

    // Write Channel Instance
    AXI_Lite_Write_Channel #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_channel (
        .clk(ACLK),
        .rst_n(ARESETN),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .write_addr(write_addr),
        .write_en(write_en)
    );
    
    // Read Channel Instance
    AXI_Lite_Read_Channel #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) read_channel (
        .clk(ACLK),
        .rst_n(ARESETN),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .read_addr(read_addr),
        .read_en(read_en),
        .read_data(read_data)
    );

endmodule

module Register_Bank #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input                       clk,
    input                       rst_n,
    input  [ADDR_WIDTH-1:0]     write_addr,
    input                       write_en,
    input  [DATA_WIDTH-1:0]     write_data,
    input  [ADDR_WIDTH-1:0]     read_addr,
    input                       read_en,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg [DATA_WIDTH-1:0] comp_a,
    output reg [DATA_WIDTH-1:0] comp_b,
    output reg                  ctrl
);

    // Register address definitions
    localparam ADDR_COMP_A = 4'h0;
    localparam ADDR_COMP_B = 4'h4;
    localparam ADDR_CTRL   = 4'h8;

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_a <= {DATA_WIDTH{1'b0}};
            comp_b <= {DATA_WIDTH{1'b0}};
            ctrl <= 1'b0;
        end else if (write_en) begin
            case(write_addr)
                ADDR_COMP_A: comp_a <= write_data;
                ADDR_COMP_B: comp_b <= write_data;
                ADDR_CTRL:   ctrl <= write_data[0];
            endcase
        end
    end

    // Read operation
    always @(posedge clk) begin
        if (read_en) begin
            case(read_addr)
                ADDR_COMP_A: read_data <= comp_a;
                ADDR_COMP_B: read_data <= comp_b;
                ADDR_CTRL:   read_data <= {{(DATA_WIDTH-1){1'b0}}, ctrl};
                default:     read_data <= {DATA_WIDTH{1'b0}};
            endcase
        end
    end
endmodule

module Comparator_Logic (
    input                clk,
    input                rst_n,
    input  [31:0]        comp_a,
    input  [31:0]        comp_b,
    input                ctrl,
    output               irq
);

    wire comp_result;
    reg  irq_reg;
    
    // Compare operation
    assign comp_result = (comp_a == comp_b);
    
    // IRQ generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            irq_reg <= 1'b0;
        else
            irq_reg <= ctrl & comp_result;
    end
    
    assign irq = irq_reg;
endmodule