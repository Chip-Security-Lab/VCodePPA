//SystemVerilog
module parallel_arbiter #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] req_i,
    output logic [WIDTH-1:0] grant_o
);
    // Pipeline stage 1: Request signal registration
    logic [WIDTH-1:0] req_registered;
    // Pipeline stage 2: Priority mask signals
    logic [WIDTH-1:0] pri_mask;
    // Pipeline stage 3: Grant output signals
    logic [WIDTH-1:0] grant_internal;
    
    // Main control - synchronize all pipeline stages
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_registered <= '0;
            grant_o <= '0;
        end else begin
            // Stage 1: Register input requests
            req_registered <= req_i;
            // Stage 3: Register final grant output
            grant_o <= grant_internal;
        end
    end
    
    // Stage 2: Priority mask generation datapath
    request_mask_generator #(
        .WIDTH(WIDTH)
    ) req_mask_gen (
        .clk          (clk),
        .rst_n        (rst_n),
        .req_i        (req_registered),
        .pri_mask_o   (pri_mask)
    );
    
    // Stage 3: Grant signal generation datapath
    grant_generator #(
        .WIDTH(WIDTH)
    ) grant_gen (
        .clk          (clk),
        .rst_n        (rst_n),
        .pri_mask_i   (pri_mask),
        .grant_o      (grant_internal)
    );
    
endmodule

// Submodule: Request mask generator with pipelined structure
module request_mask_generator #(
    parameter WIDTH = 8
) (
    input  logic                clk,
    input  logic                rst_n,
    input  logic [WIDTH-1:0]    req_i,
    output logic [WIDTH-1:0]    pri_mask_o
);
    // Internal signals for datapath segmentation
    logic [WIDTH*2-1:0] extended_req;      // Extended request vector
    logic [WIDTH*2-1:0] shifted_extended;  // Shifted extended vector
    logic [WIDTH-1:0]   shifted_mask;      // Shifted mask for priority
    logic [WIDTH-1:0]   priority_mask;     // Final priority mask before registration
    
    // Pipeline Stage 1: Extend and shift operations
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            extended_req <= '0;
            shifted_extended <= '0;
        end else begin
            // Create extended request vector
            extended_req <= {req_i, {WIDTH{1'b0}}};
            // Create shifted extended vector
            shifted_extended <= {req_i, {WIDTH{1'b0}}} >> 1;
        end
    end
    
    // Pipeline Stage 2: Extract shifted mask and calculate priority mask
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_mask <= '0;
            priority_mask <= '0;
        end else begin
            // Extract the shifted mask from the extended vector
            shifted_mask <= shifted_extended[WIDTH*2-1:WIDTH];
            // Calculate priority mask
            priority_mask <= req_i & ~shifted_mask;
        end
    end
    
    // Pipeline Stage 3: Register output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pri_mask_o <= '0;
        end else begin
            pri_mask_o <= priority_mask;
        end
    end
    
endmodule

// Submodule: Grant generator with pipelined structure
module grant_generator #(
    parameter WIDTH = 8
) (
    input  logic                clk,
    input  logic                rst_n,
    input  logic [WIDTH-1:0]    pri_mask_i,
    output logic [WIDTH-1:0]    grant_o
);
    // Internal signals for datapath segmentation
    logic [WIDTH-1:0] inverted_mask;       // Inverted priority mask
    logic [WIDTH-1:0] incremented_mask;    // Incremented inverted mask
    logic [WIDTH-1:0] preliminary_grant;   // Preliminary grant signal
    
    // Pipeline Stage 1: Invert and increment operations
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_mask <= '0;
            incremented_mask <= '0;
        end else begin
            // Invert the priority mask
            inverted_mask <= ~pri_mask_i;
            // Increment the inverted mask
            incremented_mask <= (~pri_mask_i) + 1'b1;
        end
    end
    
    // Pipeline Stage 2: Calculate preliminary grant
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            preliminary_grant <= '0;
        end else begin
            // Calculate preliminary grant by extracting lowest bit
            preliminary_grant <= pri_mask_i & incremented_mask;
        end
    end
    
    // Pipeline Stage 3: Register final grant output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= '0;
        end else begin
            grant_o <= preliminary_grant;
        end
    end
    
endmodule